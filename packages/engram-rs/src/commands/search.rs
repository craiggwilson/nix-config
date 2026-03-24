use crate::config::Config;
use crate::db;
use crate::embed;
use anyhow::{Context, Result};
use serde::Serialize;

/// Arguments for the `search` command.
pub struct SearchArgs {
    pub query: String,
    pub limit: usize,
    pub json: bool,
}

/// A single search result for JSON serialization.
#[derive(Serialize)]
pub struct JsonResult {
    pub path: String,
    pub classification: String,
    pub strength: f64,
    pub score: f64,
    pub snippet: String,
}

/// Execute the `search` command.
///
/// Embeds the query, performs brute-force cosine similarity against all stored
/// embeddings, and prints results either as a numbered human-readable list or
/// as a JSON array.
pub fn run(cfg: &Config, args: SearchArgs) -> Result<()> {
    let query_embedding = embed::embed(&args.query).context("failed to embed query")?;

    let conn = db::open(&cfg.db_path)?;
    let results = db::search(&conn, &query_embedding, args.limit)
        .context("failed to search database")?;

    if args.json {
        print_json(&results)?;
    } else {
        print_human(&results);
    }

    Ok(())
}

fn print_json(results: &[(db::SearchResult, f64)]) -> Result<()> {
    let json_results: Vec<JsonResult> = results
        .iter()
        .map(|(r, score)| JsonResult {
            path: r.path.clone(),
            classification: r.classification.clone(),
            strength: r.strength,
            score: *score,
            snippet: snippet(&r.content, 200),
        })
        .collect();

    let output = serde_json::to_string_pretty(&json_results)
        .context("failed to serialize search results to JSON")?;
    println!("{output}");
    Ok(())
}

fn print_human(results: &[(db::SearchResult, f64)]) {
    if results.is_empty() {
        println!("No results found.");
        return;
    }

    for (i, (result, score)) in results.iter().enumerate() {
        println!(
            "{}. [{}] {} (strength: {:.3}, score: {:.3})",
            i + 1,
            result.classification,
            result.path,
            result.strength,
            score,
        );
        println!("   {}", snippet(&result.content, 200));
        println!();
    }
}

/// Return the first `max_chars` characters of `text`, trimmed of leading whitespace.
fn snippet(text: &str, max_chars: usize) -> String {
    let trimmed = text.trim();
    if trimmed.chars().count() <= max_chars {
        trimmed.to_string()
    } else {
        let truncated: String = trimmed.chars().take(max_chars).collect();
        format!("{truncated}…")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_snippet_short() {
        assert_eq!(snippet("hello", 200), "hello");
    }

    #[test]
    fn test_snippet_truncated() {
        let long = "a".repeat(300);
        let s = snippet(&long, 200);
        assert!(s.ends_with('…'));
        // 200 chars + ellipsis
        assert!(s.chars().count() == 201);
    }

    #[test]
    fn test_snippet_trims_whitespace() {
        assert_eq!(snippet("  hello  ", 200), "hello");
    }
}
