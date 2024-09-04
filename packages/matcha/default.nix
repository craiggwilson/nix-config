{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  wayland,
  wayland-protocols,
  wayland-scanner,
}:

stdenv.mkDerivation {
  pname = "matcha";
  version = "1.1.2";
  src = fetchurl {
    url = "https://codeberg.org/QuincePie/matcha/archive/1.1.2.tar.gz";
    sha256 = "3y42qikOlPsUoWFuXSSvu43ITrMcLJZ3HoHLQGnX2KM=";
  };

  nativeBuildInputs = [
    meson
    ninja
    wayland-scanner
    pkg-config
  ];
  buildInputs = [
    wayland
    wayland-protocols
  ];

  meta = {
    homepage = "https://codeberg.org/QuincePie/matcha";
    description = "An idle inactivity monitor for Wayland";
    license = lib.licenses.mit;
    mainProgram = "matcha";
    platforms = lib.platforms.linux;
  };
}
