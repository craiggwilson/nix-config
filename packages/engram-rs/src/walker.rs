use crate::ocr;
use anyhow::{Context, Result};
use ignore::WalkBuilder;
use serde::Deserialize;
use std::path::{Path, PathBuf};

/// Extensions treated as markdown — frontmatter parsing is attempted.
const MARKDOWN_EXTENSIONS: &[&str] = &["md", "mdx", "markdown"];

/// Extensions treated as PDF documents.
const PDF_EXTENSIONS: &[&str] = &["pdf"];

/// Extensions treated as images — OCR is attempted.
const IMAGE_EXTENSIONS: &[&str] = &["jpg", "jpeg", "png", "gif", "bmp", "webp", "tiff", "tif"];

/// Number of bytes to sample when probing for binary content.
const BINARY_PROBE_BYTES: usize = 8192;

/// A parsed file from the vault.
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
        .hidden(true)
        .git_ignore(true)
        .add_custom_ignore_filename(".engramignore")
        .build();

    let mut files = Vec::new();

    for entry in walker {
        let entry = entry.context("failed to read directory entry")?;
        let path = entry.path();

        if !path.is_file() {
            continue;
        }

        let ext = path.extension().and_then(|e| e.to_str()).unwrap_or("").to_lowercase();
        let ext = ext.as_str();
        let parse_result = if MARKDOWN_EXTENSIONS.contains(&ext) {
            Some(parse_markdown(path))
        } else if PDF_EXTENSIONS.contains(&ext) {
            Some(parse_pdf(path))
        } else if IMAGE_EXTENSIONS.contains(&ext) {
            Some(parse_image(path))
        } else if is_text_file(path) {
            Some(parse_text(path))
        } else {
            None
        };

        match parse_result {
            Some(Ok(f)) => files.push(f),
            Some(Err(e)) => {
                // Log but don't abort the walk for a single bad file.
                eprintln!("warning: skipping {}: {e}", path.display());
            }
            None => {}
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

/// Read the modification time of a file as Unix seconds.
fn mtime(path: &Path) -> Result<i64> {
    Ok(path
        .metadata()
        .with_context(|| format!("failed to stat {}", path.display()))?
        .modified()
        .with_context(|| format!("failed to get mtime for {}", path.display()))?
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64)
}

/// Returns true if the file appears to be text — reads the first
/// `BINARY_PROBE_BYTES` and checks for null bytes and valid UTF-8.
/// This mirrors the heuristic used by git and ripgrep.
fn is_text_file(path: &Path) -> bool {
    let mut buf = vec![0u8; BINARY_PROBE_BYTES];
    let n = match std::fs::File::open(path).and_then(|mut f| {
        use std::io::Read;
        f.read(&mut buf)
    }) {
        Ok(n) => n,
        Err(_) => return false,
    };
    let sample = &buf[..n];
    // Null bytes → binary.
    if sample.contains(&0u8) {
        return false;
    }
    // Invalid UTF-8 → binary.
    std::str::from_utf8(sample).is_ok()
}

/// Parse a plain text file into a [`File`], using the filename stem as title.
fn parse_text(path: &Path) -> Result<File> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read {}", path.display()))?;

    let mtime = mtime(path)?;

    let title = path
        .file_stem()
        .unwrap_or_default()
        .to_string_lossy()
        .to_string();

    let doc_type = path
        .extension()
        .and_then(|e| e.to_str())
        .map(|e| e.to_lowercase());

    Ok(File {
        path: path.to_path_buf(),
        title,
        content,
        mtime,
        doc_type,
        tags: None,
    })
}

/// Parse a PDF file into a [`File`] by extracting its text content.
///
/// Pages with no extractable text (e.g. scanned pages) are silently skipped.
/// Returns an error if the file cannot be read or parsed at all.
fn parse_pdf(path: &Path) -> Result<File> {
    let content = pdf_extract::extract_text(path)
        .with_context(|| format!("failed to extract text from PDF {}", path.display()))?;

    // Normalise whitespace — pdf-extract can produce runs of blank lines.
    let content = content
        .lines()
        .map(|l| l.trim())
        .filter(|l| !l.is_empty())
        .collect::<Vec<_>>()
        .join("\n");

    let mtime = mtime(path)?;

    let title = path
        .file_stem()
        .unwrap_or_default()
        .to_string_lossy()
        .to_string();

    Ok(File {
        path: path.to_path_buf(),
        title,
        content,
        mtime,
        doc_type: Some("pdf".to_string()),
        tags: None,
    })
}

/// Parse an image file into a [`File`] by running OCR on it.
///
/// Returns an error if the image cannot be decoded. Files where no text is
/// detected produce an empty `content` and are still indexed (so the filename
/// is searchable), but will embed poorly — callers may choose to skip them.
fn parse_image(path: &Path) -> Result<File> {
    let content = ocr::extract_text(path)
        .with_context(|| format!("failed to OCR {}", path.display()))?;

    let mtime = mtime(path)?;

    let title = path
        .file_stem()
        .unwrap_or_default()
        .to_string_lossy()
        .to_string();

    let ext = path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("image")
        .to_lowercase();

    Ok(File {
        path: path.to_path_buf(),
        title,
        content,
        mtime,
        doc_type: Some(ext),
        tags: None,
    })
}

/// Parse a markdown file into a [`File`], attempting frontmatter extraction.
fn parse_markdown(path: &Path) -> Result<File> {
    let raw = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read {}", path.display()))?;

    let mtime = mtime(path)?;

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

    let doc_type = path
        .extension()
        .and_then(|e| e.to_str())
        .map(|e| e.to_lowercase())
        .or_else(|| Some("md".to_string()));

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
