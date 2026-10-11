let
  overrides = builtins.fromTOML (builtins.readFile ./rust-toolchain.toml);
in
{
  substrate.devenv.shells.mongotune =
    { lib, pkgs, ... }:
    let
      packages = with pkgs; [
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
    in
    {
      # A work shell: the rustup toolchain below only applies inside the
      # checkout, so enterShell checks for it. Under an impure evaluation the
      # root follows you into the checkout; under a pure one it falls back to
      # $HOME, because devenv creates `<root>/.devenv` eagerly and pointing it
      # at an absent checkout would build the tree.
      devenv.root =
        let
          pwd = builtins.getEnv "PWD";
        in
        if pwd != "" then pwd else "/home/craig";
      inherit packages;
      env = {
        LD_LIBRARY_PATH = lib.makeLibraryPath packages;
        RUST_BACKTRACE = 1;
        RUSTC_VERSION = overrides.toolchain.channel;
      };
      enterShell = ''
        if [ ! -d "$DEVENV_ROOT" ]; then
          echo "mongotune is not checked out at $DEVENV_ROOT; skipping shell setup" >&2
        else
          export PATH="$PATH:''${CARGO_HOME:-$HOME/.cargo}/bin"
          export PATH="$PATH:''${RUSTUP_HOME:-$HOME/.rustup}/toolchains/$RUSTC_VERSION-x86_64-unknown-linux-gnu/bin/"
        fi
      '';
    };
}
