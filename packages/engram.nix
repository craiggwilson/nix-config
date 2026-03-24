{ lib, pkgs, ... }:
pkgs.buildGoModule {
  pname = "engram";
  version = "0.1.0";

  src = lib.cleanSource ./engram;

  vendorHash = "sha256-t5Zuu7OJryr9Moex2XKpixuT9MG27vogcl0Vil5B9co=";

  nativeBuildInputs = [ pkgs.pkg-config ];

  buildInputs = [
    pkgs.sqlite
    pkgs.onnxruntime
  ];

  # sqlite-vec-go-bindings/cgo requires sqlite3.h at compile time
  env.CGO_ENABLED = "1";

  ldflags = [
    "-X github.com/craiggwilson/engram/internal/embed.OnnxRuntimePath=${pkgs.onnxruntime}/lib/libonnxruntime.so"
  ];

  meta = {
    description = "Local memory and search tool for markdown vaults";
    mainProgram = "engram";
    platforms = lib.platforms.linux;
  };
}
