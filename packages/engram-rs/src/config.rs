use anyhow::{Context, Result};
use directories::BaseDirs;
use std::path::{Path, PathBuf};

/// Configuration loaded from a TOML file.
#[derive(Debug, Default, serde::Deserialize)]
pub struct FileConfig {
    pub db: Option<String>,
    pub memory_path: Option<String>,
    #[serde(default)]
    pub indexed_paths: Vec<String>,
}

/// Global configuration derived from CLI flags and file config.
#[derive(Debug, Clone)]
pub struct Config {
    /// Path to the SQLite database file.
    pub db_path: PathBuf,
    /// Directory where memory markdown files are stored.
    pub memory_path: PathBuf,
    /// Additional directories to index alongside memory_path.
    pub indexed_paths: Vec<PathBuf>,
}

impl Config {
    /// Construct a Config, expanding all paths.
    /// CLI arguments take precedence over file config, which takes precedence over defaults.
    pub fn new(
        config_path: Option<String>,
        db: Option<String>,
        memory_path: Option<String>,
        indexed_paths: Vec<String>,
    ) -> Result<Self> {
        let default_data_dir = BaseDirs::new()
            .map(|b| b.data_dir().join("engram"))
            .context("could not determine XDG data directory")?;

        // Load file config
        let file_cfg = if let Some(path) = config_path {
            load_file_config(Path::new(&path))
                .context("failed to load config file")?
        } else {
            let default_path = default_config_path()?;
            load_file_config(&default_path)?
        };

        // Merge with priority: CLI > file > defaults
        let db_path = if let Some(p) = db {
            expand_path(&p).context("failed to expand db path")?
        } else if let Some(p) = file_cfg.db {
            expand_path(&p).context("failed to expand db path from config file")?
        } else {
            default_data_dir.join("engram.db")
        };

        let memory_path = if let Some(p) = memory_path {
            expand_path(&p).context("failed to expand memory-path")?
        } else if let Some(p) = file_cfg.memory_path {
            expand_path(&p).context("failed to expand memory-path from config file")?
        } else {
            default_data_dir.join("memories")
        };

        // Merge indexed_paths: CLI + file (not overriding)
        let mut all_indexed_paths = indexed_paths;
        all_indexed_paths.extend(file_cfg.indexed_paths);

        let indexed_paths = all_indexed_paths
            .iter()
            .map(|p| expand_path(p).context("failed to expand indexed-path"))
            .collect::<Result<Vec<_>>>()?;

        Ok(Self {
            db_path,
            memory_path,
            indexed_paths,
        })
    }
}

/// Load config from a TOML file. Returns default FileConfig if the file doesn't exist.
pub fn load_file_config(path: &Path) -> Result<FileConfig> {
    if !path.exists() {
        return Ok(FileConfig::default());
    }

    let content = std::fs::read_to_string(path)
        .context("failed to read config file")?;
    let cfg = toml::from_str(&content)
        .context("failed to parse TOML config file")?;
    Ok(cfg)
}

/// Returns $XDG_CONFIG_HOME/engram/engram.toml
pub fn default_config_path() -> Result<PathBuf> {
    let config_dir = BaseDirs::new()
        .map(|b| b.config_dir().join("engram/engram.toml"))
        .context("could not determine XDG config directory")?;
    Ok(config_dir)
}

/// Expand `~` and `$VAR` / `${VAR}` in a path string.
pub fn expand_path(path: &str) -> Result<PathBuf> {
    let with_home = if path.starts_with("~/") || path == "~" {
        let home = std::env::var("HOME").context("HOME environment variable not set")?;
        path.replacen('~', &home, 1)
    } else {
        path.to_string()
    };

    // Expand $VAR and ${VAR} references.
    let expanded = expand_env_vars(&with_home)?;

    Ok(PathBuf::from(expanded))
}

/// Replace `$VAR` and `${VAR}` occurrences with their environment values.
fn expand_env_vars(s: &str) -> Result<String> {
    let mut result = String::with_capacity(s.len());
    let mut chars = s.chars().peekable();

    while let Some(ch) = chars.next() {
        if ch != '$' {
            result.push(ch);
            continue;
        }

        // Determine variable name.
        let var_name: String = if chars.peek() == Some(&'{') {
            chars.next(); // consume '{'
            let name: String = chars.by_ref().take_while(|&c| c != '}').collect();
            name
        } else {
            chars
                .by_ref()
                .take_while(|c| c.is_alphanumeric() || *c == '_')
                .collect()
        };

        if var_name.is_empty() {
            result.push('$');
        } else {
            let value = std::env::var(&var_name)
                .with_context(|| format!("environment variable ${var_name} not set"))?;
            result.push_str(&value);
        }
    }

    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[ignore = "relies on env mutation which is unreliable in sandboxed builds"]
    fn test_expand_tilde() {
        std::env::set_var("HOME", "/home/testuser");
        let p = expand_path("~/foo/bar").unwrap();
        assert_eq!(p, PathBuf::from("/home/testuser/foo/bar"));
    }

    #[test]
    #[ignore = "relies on env mutation which is unreliable in sandboxed builds"]
    fn test_expand_env_var() {
        std::env::set_var("MY_TEST_VAR", "/some/path");
        let p = expand_path("$MY_TEST_VAR/sub").unwrap();
        assert_eq!(p, PathBuf::from("/some/path/sub"));
    }

    #[test]
    #[ignore = "relies on env mutation which is unreliable in sandboxed builds"]
    fn test_expand_braced_env_var() {
        std::env::set_var("MY_TEST_VAR2", "/braced");
        let p = expand_path("${MY_TEST_VAR2}/sub").unwrap();
        assert_eq!(p, PathBuf::from("/braced/sub"));
    }

    #[test]
    fn test_no_expansion_needed() {
        let p = expand_path("/absolute/path").unwrap();
        assert_eq!(p, PathBuf::from("/absolute/path"));
    }
}
