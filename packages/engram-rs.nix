{ lib, pkgs, ... }:
let
  modelFiles = {
    safetensors = pkgs.fetchurl {
      url = "https://huggingface.co/thenlper/gte-small/resolve/main/model.safetensors";
      hash = "sha256-mh65C7rDI+oIqlYptiT+auddsSG5BHmcImah4sLeItI=";
    };
    tokenizer = pkgs.fetchurl {
      url = "https://huggingface.co/thenlper/gte-small/resolve/main/tokenizer.json";
      hash = "sha256-2g55kzue1ReYo64niT08X6SiARJs73VYYpbfm00sYqA=";
    };
    config = pkgs.fetchurl {
      url = "https://huggingface.co/thenlper/gte-small/resolve/main/config.json";
      hash = "sha256-ACc837PgXHME0YAnC974ra5FAj5738OWM4vdgVlD3Fk=";
    };
    ocrDetection = pkgs.fetchurl {
      url = "https://ocrs-models.s3-accelerate.amazonaws.com/text-detection.rten";
      hash = "sha256-8Vz7Vr0CxL9HiiA0OYZQSh8B4WZcKzoK1mNA8FSxtco=";
    };
    ocrRecognition = pkgs.fetchurl {
      url = "https://ocrs-models.s3-accelerate.amazonaws.com/text-recognition.rten";
      hash = "sha256-5ISGbUzOQDF1vY0AsSj+sIq0LiCN4w5CzZiJ2PFzWm4=";
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
  OCR_DETECTION_MODEL = modelFiles.ocrDetection;
  OCR_RECOGNITION_MODEL = modelFiles.ocrRecognition;

  meta = {
    description = "Local memory and search tool for markdown vaults";
    mainProgram = "engram";
    platforms = lib.platforms.linux;
  };
}
