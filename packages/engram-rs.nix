{ lib, pkgs, ... }:
let
  modelFiles = {
    safetensors = pkgs.fetchurl {
      url = "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/model.safetensors";
      hash = "sha256-U6pRFy0ULInZASzOFa5NbMDKaJWJURQ3nKy0+rEo2ds=";
    };
    tokenizer = pkgs.fetchurl {
      url = "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/tokenizer.json";
      hash = "sha256-vlDDYo8r9bteOn8XsfdGEbJWGjon7qsF5aow9BFXIDc=";
    };
    config = pkgs.fetchurl {
      url = "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/config.json";
      hash = "sha256-lT+cDUY0hrEKaHHML9WfIjsscBhPSYFefvvKtdiQi0E=";
    };
  };
in
pkgs.rustPlatform.buildRustPackage {
  pname = "engram";
  version = "0.1.0";

  src = lib.cleanSource ./engram-rs;

  cargoLock.lockFile = ./engram-rs/Cargo.lock;

  # Pass pre-fetched model files to build.rs via env vars.
  MODEL_SAFETENSORS = modelFiles.safetensors;
  TOKENIZER_JSON = modelFiles.tokenizer;
  CONFIG_JSON = modelFiles.config;

  meta = {
    description = "Local memory and search tool for markdown vaults";
    mainProgram = "engram";
    platforms = lib.platforms.linux;
  };
}
