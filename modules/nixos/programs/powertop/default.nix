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
    enable = lib.hdwlinux.mkEnableOption "powertop" true;
    autotune = lib.mkOption {
      description = "Whether to run powertop --auto-tune at startup.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.powertop ];

    powerManagement.powertop.enable = true;
  };
}
