{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.fastfetch;
in
{
  options.hdwlinux.programs.fastfetch = {
    enable = lib.hdwlinux.mkEnableOption "fastfetch" true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.fastfetch
    ];
  };
}
