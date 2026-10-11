{
  substrate.devenv.shells.rust =
    {
      lib,
      pkgs,
      ...
    }:
    let
      packages = with pkgs; [
        (rust-bin.stable.latest.default.override {
          extensions = [
            "rust-src"
            "rust-analyzer"
          ];
        })

        cargo-deny
        cargo-generate
        cargo-machete

        # pkg-config
        # atk
        # cairo
        #glib
        # gnome2.pango
        # gtkd

        fontconfig
        libxkbcommon
        libGL

        # WINIT_UNIX_BACKEND=wayland
        wayland

        # WINIT_UNIX_BACKEND=x11
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXi
        xorg.libX11
      ];
    in
    {
      # See the note in shells/go: PWD when the evaluation can see it, the literal
      # when it cannot.
      devenv.root =
        let
          pwd = builtins.getEnv "PWD";
        in
        if pwd != "" then pwd else "/home/craig";
      inherit packages;
      env = {
        LD_LIBRARY_PATH = lib.makeLibraryPath packages;
        RUST_BACKTRACE = 1;
      };
      # Not `exec`: replacing this shell makes `nix develop .#rust --command ...`
      # print nothing, because zsh takes over before the command runs.
      enterShell = "zsh";
    };
}
