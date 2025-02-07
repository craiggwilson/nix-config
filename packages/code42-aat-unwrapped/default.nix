{
  lib,
  pkgs,
  stdenv,
  autoPatchelfHook,
  ...
}:
let
  weird-version = "1.12.3-5";
  version = lib.replaceStrings [ "-" ] [ "." ] weird-version;
in
stdenv.mkDerivation rec {
  inherit version;
  name = "code42-aat";
  src = pkgs.fetchurl {
    url = "https://download-incydr.code42.com/installs/agent/aat/com/code42/agent/agent-launcher-ubuntu24_04/${version}/code42-aat_${weird-version}%2Bubuntu2404_amd64.deb";
    sha256 = "sha256-SgGblRt1tfNlzpyGN6uFGb3Kl8z5iY7gDzUmldlDnIQ=";
  };
  sourceRoot = "opt/code42-aat";

  unpackCmd = ''
    dpkg-deb -x "${src}" .
  '';

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    pkgs.curl
    pkgs.dpkg
    pkgs.libuuid
  ];

  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  meta = with lib; {
    description = "Code42 AAT";
    homepage = "http://www.code42.com/";
    license = licenses.unfree;
    platforms = platforms.linux;
    mainProgram = "code42-aat";
  };
}
