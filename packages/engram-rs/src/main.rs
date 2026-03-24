mod commands;
mod config;
mod db;
mod embed;
mod walker;

use anyhow::Result;
use clap::{Parser, Subcommand};
use commands::{add, decay, ingest, search};

/// engram — semantic memory CLI backed by all-MiniLM-L6-v2.
#[derive(Parser)]
#[command(name = "engram", version, about)]
struct Cli {
    /// Path to engram config file (default: $XDG_CONFIG_HOME/engram/engram.toml).
    #[arg(long, global = true, env = "ENGRAM_CONFIG")]
    config: Option<String>,

    /// Path to the SQLite database file.
    #[arg(long, global = true, env = "ENGRAM_DB")]
    db: Option<String>,

    /// Directory where memory markdown files are stored.
    #[arg(long, global = true, env = "ENGRAM_MEMORY_PATH")]
    memory_path: Option<String>,

    /// Additional directories to index (repeatable).
    #[arg(long = "indexed-path", global = true, action = clap::ArgAction::Append)]
    indexed_paths: Vec<String>,

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

    /// Apply Ebbinghaus decay to episodic memories.
    Decay,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    let cfg = config::Config::new(cli.config, cli.db, cli.memory_path, cli.indexed_paths)?;

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

        Command::Ingest { full } => ingest::run(&cfg, ingest::IngestArgs { full }),

        Command::Decay => decay::run(&cfg, decay::DecayArgs),
    }
}
