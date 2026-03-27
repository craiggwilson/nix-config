use std::fs;
use std::io::Read;
use std::path::PathBuf;

const HF_BASE: &str = "https://huggingface.co/thenlper/gte-small/resolve/main";
const OCR_BASE: &str = "https://ocrs-models.s3-accelerate.amazonaws.com";

/// Extracts the HuggingFace model ID (e.g. "thenlper/gte-small") from HF_BASE.
fn model_id() -> &'static str {
    // URL format: https://huggingface.co/<org>/<model>/resolve/main
    HF_BASE
        .trim_start_matches("https://huggingface.co/")
        .split("/resolve/")
        .next()
        .expect("HF_BASE must be a valid HuggingFace URL")
}

fn main() {
    println!("cargo:rerun-if-changed=build.rs");

    // Expose the embedded model ID to the crate at compile time.
    println!("cargo:rustc-env=ENGRAM_EMBEDDED_MODEL={}", model_id());

    let out_dir = std::env::var("OUT_DIR").expect("OUT_DIR not set");
    let out_path = PathBuf::from(&out_dir);

    println!("cargo:warning=Downloading embedding model files...");
    download_file("model.safetensors", &out_path, HF_BASE, "MODEL_SAFETENSORS");
    download_file("tokenizer.json", &out_path, HF_BASE, "TOKENIZER_JSON");
    download_file("config.json", &out_path, HF_BASE, "CONFIG_JSON");

    println!("cargo:warning=Downloading OCR model files...");
    download_file("text-detection.rten", &out_path, OCR_BASE, "OCR_DETECTION_MODEL");
    download_file("text-recognition.rten", &out_path, OCR_BASE, "OCR_RECOGNITION_MODEL");

    println!("cargo:warning=All model files ready");
}

fn download_file(filename: &str, out_dir: &PathBuf, base_url: &str, env_var: &str) {
    let target_path = out_dir.join(filename);

    // Skip download if file already exists (incremental builds).
    if target_path.exists() {
        println!("cargo:warning=File {} already exists, skipping download", filename);
        return;
    }

    // Check for pre-fetched file via env var (used in Nix builds).
    if let Ok(src) = std::env::var(env_var) {
        std::fs::copy(&src, &target_path)
            .unwrap_or_else(|e| panic!("Failed to copy {} from {}: {}", filename, src, e));
        println!("cargo:warning=Copied {} from {}", filename, src);
        return;
    }

    // Fall back to HTTP download (for local development builds).
    let url = format!("{}/{}", base_url, filename);
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
