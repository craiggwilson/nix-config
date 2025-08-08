{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.coreutils;
in
{
  options.hdwlinux.programs.coreutils = {
    enable = lib.hdwlinux.mkEnableOption "coreutils" true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.coreutils
    ];
  };
}
