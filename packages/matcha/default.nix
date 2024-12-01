{
  stdenv,
  lib,
  fetchgit,
  pkg-config,
  meson,
  ninja,
  wayland,
  wayland-protocols,
  wayland-scanner,
}:
stdenv.mkDerivation rec {
  pname = "matcha";
  version = "1.1.2";

  src = fetchgit {
    url = "https://codeberg.org/QuincePie/matcha.git";
    hash = "sha256-WhpLwINCuXYxa9y8o4bcFsryvD/VcGi/9VimwJmbobw=";
  };

  nativeBuildInputs = [
    pkg-config
    meson
    ninja
    wayland
    wayland-protocols
    wayland-scanner
  ];

  meta = with lib; {
    description = "An Idle Inhibitor for Wayland.";
    homepage = "https://codeberg.org/QuincePie/matcha";
    license = licenses.mit;
    platforms = with platforms; linux;
    mainProgram = pname;
  };
}
