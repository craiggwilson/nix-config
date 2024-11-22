{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.powertop;
in
{
  options.hdwlinux.programs.powertop = {
    enable = lib.mkOption {
      description = "Whether to enable powertop.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.powertop ];
  };
}
