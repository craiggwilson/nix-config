{
  lib,
  inputs,
  pkgs,
  stdenv,
  requireFile,
  ...
}:
let
  src = requireFile rec {
    name = "falcon-sensor_9_10_11_12.deb";
    sha256 = "0gak6p8fzvifqy2yz03fi12m1yqs5w3xdn17j2qji3yk08vv61lw";
    message = ''
      In order to install the CrowdStrike Falcon Sensor, you must first download the 
      debian package from here:
        
        https://wiki.corp.mongodb.com/display/SEC/CrowdStrike+Sensor+Installation+Guide+for+Linux.

      Once you have downloaded the file, please use the following
      commands and re-run the installation.

      mv "Debian 9_10_11_12.deb" \$PWD/${name}
      nix-prefetch-url file://$\PWD/${name}
    '';
  };

  falcon-sensor = stdenv.mkDerivation rec {
    inherit src;
    buildInputs = [ pkgs.dpkg ];
    name = "falcon-sensor";
    sourceRoot = ".";

    unpackCmd = ''
      dpkg-deb -x "${src}" .
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

  falcon-env =
    pkgs.buildFHSEnv {
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
    }
    // {
      pkgs = {
        falconctl = wrapCommand "falconctl";
        falcond = wrapCommand "falcond";
        falcon-kernel-check = wrapCommand "falcon-kernel-check";
      };
    };

  wrapCommand =
    command:
    pkgs.writeScriptBin "${command}" ''
      #! ${pkgs.bash}/bin/sh

      "${falcon-env}/bin/fs-bash" -c "${falcon-env}/opt/CrowdStrike/${command} $*"
    '';
in
falcon-env
