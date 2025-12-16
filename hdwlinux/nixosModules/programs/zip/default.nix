{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.zip;
in
{
  options.hdwlinux.programs.zip = {
    enable = lib.hdwlinux.mkEnableOption "zip" true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.zip
      pkgs.unzip
    ];
  };
}
