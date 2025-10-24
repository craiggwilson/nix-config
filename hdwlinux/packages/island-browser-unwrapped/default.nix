{
  lib,
  pkgs,
  stdenv,
  autoPatchelfHook,
  requireFile,
  ...
}:
stdenv.mkDerivation rec {
  name = "island-browser";
  src = requireFile rec {
    name = "island-browser.deb";
    sha256 = "1bsfmxnii6hrq9szwgcg2g1rlb8gjk2616m90c6driq093jcyggc";
    message = ''
      In order to install the Island Browser, you must first download the 
      debian package from here:
        
        https://wiki.corp.mongodb.com/spaces/SEC/pages/346726502/Island+Browser+User+Guide.

      Once you have downloaded the file, please use the following
      commands and re-run the installation.

      mv "island-browser.deb" \$PWD/${name}
      nix-prefetch-url file://$\PWD/${name}
    '';
  };

  sourceRoot = "opt/island/island-browser";

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
    description = "Island Browser";
    homepage = "https://www.island.io/";
    license = licenses.unfree;
    platforms = platforms.linux;
    mainProgram = "island-browser";
  };
}
