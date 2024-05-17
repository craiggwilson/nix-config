{ lib, inputs, pkgs, stdenv, ... }:
let
  src = /opt/CrowdStrike + "/Debian_9_10_11_12.deb";
  falcon-sensor = stdenv.mkDerivation rec {
    inherit src;
    buildInputs = [ pkgs.dpkg ];
    name = "falcon-sensor";
    sourceRoot = ".";

    unpackCmd = ''
      dpkg-deb -x "$src" .
    '';

    installPhase = ''
      cp -r ./ $out/
      realpath $out
    '';

    meta = with lib; {
      description = "Crowdstrike Falcon Sensor";
      homepage = "https://www.crowdstrike.com/";
      license = licenses.unfree;
      platforms = platforms.linux;
      maintainers = with maintainers; [ ravloony ];
    };
  };

  falcon-env = pkgs.buildFHSUserEnv
    {
      name = "fs-bash";
      targetPkgs = pkgs: [
        pkgs.libnl
        pkgs.openssl
        pkgs.zlib
      ];

      extraInstallCommands = ''
        ln -s ${falcon-sensor}/* $out/
      '';

      runScript = "bash";
    } // {
    pkgs = {
      falconctl = wrapCommand "falconctl";
      falcond = wrapCommand "falcond";
      falcon-kernel-check = wrapCommand "falcon-kernel-check";
    };
  };

  wrapCommand = command: pkgs.writeScriptBin "${command}" ''
    #! ${pkgs.bash}/bin/sh

    "${falcon-env}/bin/fs-bash" -c "${falcon-env}/opt/CrowdStrike/${command} $*"
  '';
in
falcon-env

