{ lib, pkgs, ... }:
let
  weird-version = "1.12.21-14";
  version = lib.replaceStrings [ "-" ] [ "." ] weird-version;
in
pkgs.stdenv.mkDerivation rec {
  inherit version;
  name = "code42-aat";
  src = pkgs.fetchurl {
    url = "https://download-incydr.code42.com/installs/agent/aat/com/code42/agent/agent-launcher-ubuntu24_04/${version}/code42-aat_${weird-version}%2Bubuntu2404_amd64.deb";
    sha256 = "sha256-0ttNnbt5+rNfk0J/Js8kyuQDgj2+izSvfxe3JIWlH24=";
  };
  sourceRoot = "opt/code42-aat";

  unpackCmd = ''
    dpkg-deb -x "${src}" .
  '';

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
  ];

  buildInputs = [
    pkgs.stdenv.cc.cc.lib
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
