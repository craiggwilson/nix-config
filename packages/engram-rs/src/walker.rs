use anyhow::{Context, Result};
use ignore::WalkBuilder;
use serde::Deserialize;
use std::path::{Path, PathBuf};

/// A parsed markdown file from the vault.
#[derive(Debug, Clone)]
pub struct File {
    /// Absolute path to the file.
    pub path: PathBuf,
    /// Extracted title (frontmatter > first heading > filename stem).
    pub title: String,
    /// Raw body content (everything after frontmatter).
    pub content: String,
    /// File modification time as Unix seconds.
    pub mtime: i64,
    /// `type` field from frontmatter, if present.
    pub doc_type: Option<String>,
    /// `tags` field from frontmatter serialized as a JSON array string, if present.
    pub tags: Option<String>,
}

/// Walk `root` recursively, yielding parsed markdown files.
///
/// Hidden directories (names starting with `.`) and patterns in `.gitignore`
/// are skipped automatically.
pub fn walk(root: &Path) -> Result<Vec<File>> {
    if !root.exists() {
        return Ok(vec![]);
    }

    let walker = WalkBuilder::new(root)
        .hidden(true)   // skip hidden files/dirs
        .git_ignore(true)
        .build();

    let mut files = Vec::new();

    for entry in walker {
        let entry = entry.context("failed to read directory entry")?;
        let path = entry.path();

        if !path.is_file() {
            continue;
        }

        if path.extension().and_then(|e| e.to_str()) != Some("md") {
            continue;
        }

        match parse_file(path) {
            Ok(f) => files.push(f),
            Err(e) => {
                // Log but don't abort the walk for a single bad file.
                eprintln!("warning: skipping {}: {e}", path.display());
            }
        }
    }

    Ok(files)
}

/// Walk multiple roots, deduplicating by canonical path.
pub fn walk_all(roots: &[PathBuf]) -> Result<Vec<File>> {
    let mut seen = std::collections::HashSet::new();
    let mut files = Vec::new();

    for root in roots {
        for file in walk(root)? {
            let key = file.path.to_string_lossy().to_string();
            if seen.insert(key) {
                files.push(file);
            }
        }
    }

    Ok(files)
}

/// Parse a single markdown file into a [`File`].
fn parse_file(path: &Path) -> Result<File> {
    let raw = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read {}", path.display()))?;

    let mtime = path
        .metadata()
        .with_context(|| format!("failed to stat {}", path.display()))?
        .modified()
        .with_context(|| format!("failed to get mtime for {}", path.display()))?
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64;

    let (frontmatter, body) = split_frontmatter(&raw);

    let fm: Option<Frontmatter> = frontmatter
        .and_then(|fm_str| serde_yaml::from_str(fm_str).ok());

    let title = fm
        .as_ref()
        .and_then(|fm| fm.title.clone())
        .or_else(|| extract_heading(body))
        .unwrap_or_else(|| {
            path.file_stem()
                .unwrap_or_default()
                .to_string_lossy()
                .to_string()
        });

    let doc_type = fm.as_ref().and_then(|fm| fm.doc_type.clone());

    let tags = fm.as_ref().and_then(|fm| {
        if fm.tags.is_empty() {
            None
        } else {
            serde_json::to_string(&fm.tags).ok()
        }
    });

    Ok(File {
        path: path.to_path_buf(),
        title,
        content: body.to_string(),
        mtime,
        doc_type,
        tags,
    })
}

/// Frontmatter fields we care about.
#[derive(Debug, Deserialize)]
struct Frontmatter {
    title: Option<String>,
    #[serde(rename = "type")]
    doc_type: Option<String>,
    #[serde(default)]
    tags: Vec<String>,
}

/// Split a markdown string into optional frontmatter and body.
///
/// Returns `(Some(frontmatter_str), body)` when the file starts with `---`.
fn split_frontmatter(raw: &str) -> (Option<&str>, &str) {
    if !raw.starts_with("---") {
        return (None, raw);
    }

    // Find the closing `---` delimiter.
    let after_open = &raw[3..];
    if let Some(close_pos) = after_open.find("\n---") {
        let fm = &after_open[..close_pos];
        let body_start = 3 + close_pos + 4; // skip "\n---"
        let body = raw.get(body_start..).unwrap_or("").trim_start_matches('\n');
        (Some(fm), body)
    } else {
        (None, raw)
    }
}

/// Extract the text of the first `# Heading` line from a markdown body.
fn extract_heading(body: &str) -> Option<String> {
    body.lines()
        .find(|l| l.starts_with("# "))
        .map(|l| l[2..].trim().to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_split_frontmatter_present() {
        let raw = "---\ntitle: Hello\n---\n\nBody text";
        let (fm, body) = split_frontmatter(raw);
        assert!(fm.is_some());
        assert!(fm.unwrap().contains("title: Hello"));
        assert_eq!(body, "Body text");
    }

    #[test]
    fn test_split_frontmatter_absent() {
        let raw = "# Just a heading\n\nSome content";
        let (fm, body) = split_frontmatter(raw);
        assert!(fm.is_none());
        assert_eq!(body, raw);
    }

    #[test]
    fn test_extract_heading() {
        let body = "Some intro\n\n# My Title\n\nMore text";
        assert_eq!(extract_heading(body), Some("My Title".to_string()));
    }

    #[test]
    fn test_extract_heading_none() {
        let body = "No heading here";
        assert_eq!(extract_heading(body), None);
    }
}
