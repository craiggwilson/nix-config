{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.island-browser;

  fhsEnv = pkgs.buildFHSEnv {
    name = "island-browser-bash";
    targetPkgs = pkgs: [
      pkgs.hdwlinux.island-browser-unwrapped
    ];
    includeClosures = true;
    privateTmp = true;
  };

  island-browser = pkgs.writeScriptBin "island-browser" ''
    #! ${pkgs.bash}/bin/sh

    "${fhsEnv}/bin/island-browser-bash" -c "${pkgs.hdwlinux.island-browser-unwrapped}/island-browser $*"
  '';

in
{
  options.hdwlinux.programs.island-browser = {
    enable = config.lib.hdwlinux.mkEnableOption "island-browser" false;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      island-browser
    ];
  };
}
