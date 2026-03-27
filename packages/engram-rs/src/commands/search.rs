use crate::config::Config;
use crate::db;
use crate::embed;
use anyhow::{Context, Result};
use owo_colors::OwoColorize;
use serde::Serialize;
use std::collections::HashMap;

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
    let query_embedding = embed::embed_query(&args.query, cfg.query_prefix.as_deref().unwrap_or("")).context("failed to embed query")?;

    let conn = db::open(&cfg.db_path)?;
    let results = db::search(
        &conn,
        &query_embedding,
        args.limit,
        cfg.scoring.semantic_weight,
        cfg.scoring.strength_weight,
        cfg.scoring.semantic_threshold,
        cfg.scoring.chunking.enabled,
        cfg.scoring.corpus_centering.enabled,
        cfg.scoring.mmr.enabled,
        cfg.scoring.mmr.lambda,
        cfg.scoring.bm25.enabled,
        cfg.scoring.bm25.weight,
        cfg.scoring.bm25.dense_weight,
        cfg.scoring.bm25.rrf_k,
        &args.query,
    )
    .context("failed to search database")?;

    if args.json {
        print_json(&results)?;
    } else {
        print_human(&results, cfg);
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
            snippet: super::list::truncate(&r.content, 200),
        })
        .collect();

    let output = serde_json::to_string_pretty(&json_results)
        .context("failed to serialize search results to JSON")?;
    println!("{output}");
    Ok(())
}

fn print_human(results: &[(db::SearchResult, f64)], cfg: &Config) {
    if results.is_empty() {
        println!("No results found.");
        return;
    }

    let use_color = crate::color_enabled();
    // Map each configured type name to its palette index.
    let type_index: HashMap<&str, usize> = cfg
        .memory_types
        .iter()
        .enumerate()
        .map(|(i, t)| (t.classification.as_str(), i))
        .collect();

    for (i, (result, score)) in results.iter().enumerate() {
        let num_str = format!("{}.", i + 1);
        let cls_str = format!("[{}]", result.classification);
        let score_str = format!("(score: {:.3})", score);
        let strength_str = format!("(strength: {:.3})", result.strength);
        let snippet = super::list::truncate(&result.content, 200);

        if use_color {
            // Unknown types (not in config) get the last palette slot.
            let idx = type_index
                .get(result.classification.as_str())
                .copied()
                .unwrap_or(5);
            println!(
                "{} {} {} {} {}",
                num_str.dimmed(),
                super::list::classification_label(&cls_str, idx),
                result.path,
                super::list::strength_label(&score_str, *score),
                super::list::strength_label(&strength_str, result.strength),
            );
            println!("   {}", snippet.dimmed());
        } else {
            println!(
                "{} {} {} {} {}",
                num_str, cls_str, result.path, score_str, strength_str
            );
            println!("   {}", snippet);
        }
        println!();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_truncate_short() {
        assert_eq!(super::super::list::truncate("hello", 200), "hello");
    }

    #[test]
    fn test_truncate_long() {
        let long = "a".repeat(300);
        let s = super::super::list::truncate(&long, 200);
        assert!(s.ends_with('…'));
        // 200 chars + ellipsis
        assert!(s.chars().count() == 201);
    }

    #[test]
    fn test_truncate_trims_whitespace() {
        assert_eq!(super::super::list::truncate("  hello  ", 200), "hello");
    }
}
