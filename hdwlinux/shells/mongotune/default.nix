{
  lib,
  pkgs,
  ...
}:

# let
#   extensions = [
#     "rust-src"
#     "rust-analyzer"
#   ];

#   rustStable = pkgs.rust-bin.stable.latest.default.override {
#     inherit extensions;
#   };

#   rustNightly = pkgs.rust-bin.nightly.latest.default.override {
#     inherit extensions;
#   };

#   mkShim =
#     name:
#     pkgs.writeShellApplication {
#       name = name;
#       runtimeInputs = [
#         rustNightly
#         rustStable
#       ];
#       text = ''
#         if [ "$#" -gt 0 ] && [ "''${1}" = "+nightly" ]
#         then
#           shift;
#           echo "HEREER ********"
#           exec ${rustNightly}/bin/${name} "''$@"
#         else
#           exec ${rustStable}/bin/${name} "''$@"
#         fi
#       '';
#     };
# in

let
  overrides = (builtins.fromTOML (builtins.readFile ./rust-toolchain.toml));
in
pkgs.mkShell rec {
  buildInputs = with pkgs; [
    bpftools
    bpftop
    ethtool
    mdbook
    mdbook-mermaid
    openssl
    pkg-config
    rustup
    zlib
  ];

  LD_LIBRARY_PATH = "${lib.makeLibraryPath buildInputs}";
  RUST_BACKTRACE = 1;
  RUSTC_VERSION = overrides.toolchain.channel;

  shellHook = ''
    export PATH=$PATH:''${CARGO_HOME:-~/.cargo}/bin
    export PATH=$PATH:''${RUSTUP_HOME:-~/.rustup}/toolchains/$RUSTC_VERSION-x86_64-unknown-linux-gnu/bin/
  '';
}
