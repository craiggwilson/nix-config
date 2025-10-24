{
  lib,
  pkgs,
  stdenv,
  autoPatchelfHook,
  ...
}:
let
  version = "137-137.23.1.104-7ef90c1f.23.1.104-1";
in
stdenv.mkDerivation rec {
  name = "prisma-access-browser";
  src = pkgs.fetchurl {
    url = "https://updates.talon-sec.com/releases/Prisma%20Access%20Browser/linux_deb/stable/x64/prisma-access-browser-stable_${version}_amd64.deb";
    sha256 = "sha256-9FXGLYbvab8k7d+lw/KfTpzcaToE8uKzyqsN5oT27Yw=";
  };

  sourceRoot = "opt/paloaltonetworks/pab";

  unpackCmd = ''
    dpkg-deb -x "${src}" .
  '';

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    pkgs.dpkg
    pkgs.qt5.full
    pkgs.qt6.full
    pkgs.cairo
    pkgs.cups
    pkgs.atk
    pkgs.pango
  ];

  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  meta = with lib; {
    description = "Prisma Access Browser";
    homepage = "https://get.pabrowser.com";
    license = licenses.unfree;
    platforms = platforms.linux;
    mainProgram = "PrismaAccessBrowser";
  };
}
