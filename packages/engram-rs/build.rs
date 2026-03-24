use std::fs;
use std::io::Read;
use std::path::PathBuf;

const HF_BASE: &str = "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main";

fn main() {
    println!("cargo:rerun-if-changed=build.rs");

    let out_dir = std::env::var("OUT_DIR").expect("OUT_DIR not set");
    let out_path = PathBuf::from(&out_dir);

    println!("cargo:warning=Downloading model files from HuggingFace...");

    download_file("model.safetensors", &out_path);
    download_file("tokenizer.json", &out_path);
    download_file("config.json", &out_path);

    println!("cargo:warning=Model files ready");
}

fn download_file(filename: &str, out_dir: &PathBuf) {
    let target_path = out_dir.join(filename);

    // Skip download if file already exists (incremental builds).
    if target_path.exists() {
        println!("cargo:warning=File {} already exists, skipping download", filename);
        return;
    }

    // Check for pre-fetched file via env var (used in Nix builds).
    let env_var = match filename {
        "model.safetensors" => "MODEL_SAFETENSORS",
        "tokenizer.json" => "TOKENIZER_JSON",
        "config.json" => "CONFIG_JSON",
        _ => "",
    };
    if !env_var.is_empty() {
        if let Ok(src) = std::env::var(env_var) {
            std::fs::copy(&src, &target_path)
                .unwrap_or_else(|e| panic!("Failed to copy {} from {}: {}", filename, src, e));
            println!("cargo:warning=Copied {} from {}", filename, src);
            return;
        }
    }

    // Fall back to HTTP download (for local development builds).
    let url = format!("{}/{}", HF_BASE, filename);
    println!("cargo:warning=Downloading {} from {}", filename, url);

    let resp = ureq::get(&url)
        .call()
        .unwrap_or_else(|e| panic!("Failed to download {}: {}", filename, e));

    let mut bytes = Vec::new();
    resp.into_reader()
        .read_to_end(&mut bytes)
        .unwrap_or_else(|e| panic!("Failed to read response for {}: {}", filename, e));

    fs::write(&target_path, &bytes)
        .unwrap_or_else(|e| panic!("Failed to write {}: {}", filename, e));

    println!("cargo:warning=Downloaded {} ({} bytes)", filename, bytes.len());
}
