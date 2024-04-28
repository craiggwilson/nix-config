{ lib, inputs, pkgs, stdenv,...}:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    rust-bin.stable.latest.default

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

  LD_LIBRARY_PATH = "${lib.makeLibraryPath buildInputs}";
  RUST_BACKTRACE="1";
}
