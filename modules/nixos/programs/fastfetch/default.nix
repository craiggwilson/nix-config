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
    enable = lib.mkOption {
      description = "Whether to enable fastfetch.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.fastfetch
    ];
  };
}
