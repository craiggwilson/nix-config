use crate::config::Config;
use crate::db;
use anyhow::{Context, Result};

/// Arguments for the `remove` command.
pub struct RemoveArgs {
    /// One or more memory identifiers to remove — each may be an integer ID or a file path.
    pub identifiers: Vec<String>,
}

/// Execute the `remove` command.
///
/// Removes specific memory records from the database. Each identifier may be
/// either an integer record ID (from `engram list --json`) or a full file path.
/// Also deletes the corresponding on-disk file if it exists. Prints a summary
/// of what was removed and what was not found.
pub fn run(cfg: &Config, args: RemoveArgs) -> Result<()> {
    let conn = db::open(&cfg.db_path)?;
    let mut removed = 0usize;
    let mut not_found = 0usize;

    for identifier in &args.identifiers {
        // Resolve identifier to a path: try parsing as an integer ID first.
        let path = if let Ok(id) = identifier.parse::<i64>() {
            match db::get_by_id(&conn, id)
                .with_context(|| format!("failed to look up id {id}"))?
            {
                Some(doc) if doc.is_memory => doc.path,
                Some(_) => {
                    eprintln!("not a memory: id {identifier}");
                    not_found += 1;
                    continue;
                }
                None => {
                    eprintln!("not found: id {identifier}");
                    not_found += 1;
                    continue;
                }
            }
        } else {
            // Treat as a path. get_mtime only returns Some for is_memory=1 rows.
            if db::get_mtime(&conn, identifier)?.is_none() {
                eprintln!("not found: {identifier}");
                not_found += 1;
                continue;
            }
            identifier.clone()
        };

        db::delete(&conn, &path)
            .with_context(|| format!("failed to remove {path} from database"))?;

        // Remove the on-disk file if it exists.
        let on_disk = std::path::Path::new(&path);
        if on_disk.exists() {
            std::fs::remove_file(on_disk)
                .with_context(|| format!("failed to delete file {path}"))?;
        }

        println!("removed: {path}");
        removed += 1;
    }

    if not_found > 0 {
        println!("{removed} removed, {not_found} not found");
    } else {
        println!("{removed} removed");
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_remove_args_structure() {
        let args = RemoveArgs {
            identifiers: vec!["/path1.md".to_string(), "42".to_string()],
        };
        assert_eq!(args.identifiers.len(), 2);
        assert_eq!(args.identifiers[0], "/path1.md");
        assert_eq!(args.identifiers[1], "42");
    }

    #[test]
    fn test_identifier_parsed_as_id() {
        assert!("42".parse::<i64>().is_ok());
        assert!("0".parse::<i64>().is_ok());
    }

    #[test]
    fn test_identifier_treated_as_path() {
        assert!("/some/path.md".parse::<i64>().is_err());
        assert!("memories/fact/note.md".parse::<i64>().is_err());
    }

    #[test]
    fn test_negative_id_parsed_correctly() {
        // Negative integers are valid i64 — unlikely as IDs but shouldn't panic.
        assert!("-1".parse::<i64>().is_ok());
    }
}
