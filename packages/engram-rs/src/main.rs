mod chunk;
mod commands;
mod config;
mod db;
mod embed;
mod eval;
mod ocr;
mod walker;

use anyhow::Result;
use clap::{Parser, Subcommand};
use commands::{add, clear, config as config_cmd, ingest, list, maintain, remove, search, stats, types};
use std::io::IsTerminal;
use std::sync::OnceLock;

/// Global color setting determined at startup and used by all commands.
static COLOR_ENABLED: OnceLock<bool> = OnceLock::new();

/// Returns whether color output should be enabled.
/// This is set globally in main() and respects both --no-color flag and NO_COLOR env var.
pub fn color_enabled() -> bool {
    *COLOR_ENABLED.get().unwrap_or(&false)
}

/// engram — semantic memory CLI with configurable embedding models.
#[derive(Parser)]
#[command(name = "engram", version, about)]
struct Cli {
    /// Path to engram config file (default: $XDG_CONFIG_HOME/engram/engram.toml).
    #[arg(long, global = true, env = "ENGRAM_CONFIG")]
    config: Option<String>,

    /// Disable color output. Also honoured via the NO_COLOR environment variable.
    #[arg(long, global = true)]
    no_color: bool,

    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// Add a new memory entry.
    Add {
        /// Memory classification type.
        #[arg(long = "type", value_name = "TYPE")]
        memory_type: String,

        /// Optional correlation ID for grouping related memories.
        #[arg(long)]
        correlation_id: Option<String>,

        /// Memory content.
        content: String,
    },

    /// Search memories by semantic similarity.
    Search {
        /// Maximum number of results to return.
        #[arg(long, default_value_t = 5)]
        limit: usize,

        /// Output results as JSON.
        #[arg(long)]
        json: bool,

        /// Search query.
        query: String,
    },

    /// Ingest markdown files from memory-path and indexed-paths.
    Ingest {
        /// Re-embed all files even if mtime is unchanged.
        #[arg(long)]
        full: bool,
    },

    /// Delete memories from the database.
    Clear {
        /// Limit clearing to a specific configured memory type.
        #[arg(long = "type", value_name = "TYPE")]
        memory_type: Option<String>,
    },

    /// List all memories in the database.
    List {
        /// Limit to a specific memory type.
        #[arg(long = "type", value_name = "TYPE")]
        memory_type: Option<String>,

        /// Output as JSON array.
        #[arg(long)]
        json: bool,
    },

    /// Remove specific memories by ID or path.
    Remove {
        /// One or more memory identifiers to remove (integer ID or full path).
        #[arg(required = true)]
        identifiers: Vec<String>,
    },

    /// Show statistics about the memory dataset.
    Stats {
        /// Output as JSON.
        #[arg(long)]
        json: bool,
    },

    /// Show the active configuration (merged from file, CLI flags, and defaults).
    Config {
        /// Output as JSON.
        #[arg(long)]
        json: bool,
    },

    /// List configured memory types and their descriptions.
    Types {
        /// Output as JSON array.
        #[arg(long)]
        json: bool,
    },

    /// Run maintenance tasks: apply memory decay and update corpus mean.
    Maintain,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    // Determine color setting: disabled if --no-color is set, or NO_COLOR env var is set,
    // or stdout is not a terminal.
    let use_color = !cli.no_color && std::env::var_os("NO_COLOR").is_none() && std::io::stdout().is_terminal();

    // Apply color override early, before any output.
    // set_override(true) ensures owo_colors respects our decision, not its own detection.
    if use_color {
        owo_colors::set_override(true);
    } else {
        owo_colors::set_override(false);
    }

    // Store the decision in global state for use by all commands.
    let _ = COLOR_ENABLED.set(use_color);

    let cfg = config::Config::new(cli.config)?;

    // Initialise models.
    embed::init(cfg.model_path.as_deref())?;
    ocr::init()?;
    let conn = db::open(&cfg.db_path)?;
    let active_dim = embed::embedding_dim()?;
    let active_model = cfg.model_path
        .as_deref()
        .map(|p| p.to_string_lossy().into_owned())
        .unwrap_or_else(|| embed::EMBEDDED_MODEL_ID.to_string());

    // Skip the model check for `ingest --full` — that is the recovery path
    // for a model mismatch and must be allowed to run regardless.
    let is_full_ingest = matches!(cli.command, Command::Ingest { full: true });

    match db::kv_get(&conn, "embedding_model")? {
        Some(stored_model) if !is_full_ingest => {
            let stored_dim: usize = db::kv_get(&conn, "embedding_dim")?
                .and_then(|v| v.parse().ok())
                .unwrap_or(0);
            if stored_model != active_model || stored_dim != active_dim {
                anyhow::bail!(
                    "embedding model mismatch: database was indexed with model \
                     '{stored_model}' ({stored_dim} dimensions) but the active model is \
                     '{active_model}' ({active_dim} dimensions).\n\
                     Run `engram ingest --full` to re-index with the new model."
                );
            }

            // Check index configuration parameters (only if they exist in the database).
            let active_chunk_size = cfg.scoring.chunking.chunk_size.to_string();
            let active_chunk_stride = cfg.scoring.chunking.chunk_stride.to_string();
            let active_title_boosting = if cfg.scoring.title_boosting.enabled { "true" } else { "false" };

            let mut mismatches = Vec::new();

            if let Some(stored_chunk_size) = db::kv_get(&conn, "chunk_size")? {
                if stored_chunk_size != active_chunk_size {
                    mismatches.push(format!("chunk_size: {stored_chunk_size} -> {active_chunk_size}"));
                }
            }

            if let Some(stored_chunk_stride) = db::kv_get(&conn, "chunk_stride")? {
                if stored_chunk_stride != active_chunk_stride {
                    mismatches.push(format!("chunk_stride: {stored_chunk_stride} -> {active_chunk_stride}"));
                }
            }

            if let Some(stored_title_boosting) = db::kv_get(&conn, "title_boosting")? {
                if stored_title_boosting != active_title_boosting {
                    mismatches.push(format!("title_boosting: {stored_title_boosting} -> {active_title_boosting}"));
                }
            }

            if !mismatches.is_empty() {
                anyhow::bail!(
                    "index configuration mismatch:\n\
                     {}\n\
                     Run `engram ingest --full` to re-index with the new configuration.",
                    mismatches.join("\n")
                );
            }
        }
        None => {
            // New database — record the active model and configuration.
            db::kv_set(&conn, "embedding_dim", &active_dim.to_string())?;
            db::kv_set(&conn, "embedding_model", &active_model)?;
            db::kv_set(&conn, "chunk_size", &cfg.scoring.chunking.chunk_size.to_string())?;
            db::kv_set(&conn, "chunk_stride", &cfg.scoring.chunking.chunk_stride.to_string())?;
            db::kv_set(&conn, "title_boosting", if cfg.scoring.title_boosting.enabled { "true" } else { "false" })?;
        }
        _ => {}
    }
    drop(conn);

    match cli.command {
        Command::Add {
            memory_type,
            correlation_id,
            content,
        } => add::run(
            &cfg,
            add::AddArgs {
                memory_type,
                correlation_id,
                content,
            },
        ),

        Command::Search { limit, json, query } => search::run(
            &cfg,
            search::SearchArgs {
                query,
                limit,
                json,
            },
        ),

        Command::Clear { memory_type } => {
            clear::run(&cfg, clear::ClearArgs { memory_type })
        }

        Command::List { memory_type, json } => {
            list::run(&cfg, list::ListArgs { memory_type, json })
        }

        Command::Remove { identifiers } => {
            remove::run(&cfg, remove::RemoveArgs { identifiers })
        }

        Command::Stats { json } => stats::run(&cfg, stats::StatsArgs { json }),

        Command::Config { json } => config_cmd::run(&cfg, config_cmd::ConfigArgs { json }),

        Command::Types { json } => types::run(&cfg, types::TypesArgs { json }),

        Command::Ingest { full } => {
            ingest::run(&cfg, ingest::IngestArgs { full })?;
            if full {
                // Update the stored model identity and configuration now that all embeddings are fresh.
                let conn = db::open(&cfg.db_path)?;
                db::kv_set(&conn, "embedding_dim", &active_dim.to_string())?;
                db::kv_set(&conn, "embedding_model", &active_model)?;
                db::kv_set(&conn, "chunk_size", &cfg.scoring.chunking.chunk_size.to_string())?;
                db::kv_set(&conn, "chunk_stride", &cfg.scoring.chunking.chunk_stride.to_string())?;
                db::kv_set(&conn, "title_boosting", if cfg.scoring.title_boosting.enabled { "true" } else { "false" })?;
            }
            Ok(())
        }

        Command::Maintain => maintain::run(&cfg, maintain::MaintainArgs),
    }
}
