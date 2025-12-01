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
      default = false;
    };
    postStart = lib.mkOption {
      description = "A list of bash commands to run after powertop has been autotuned.";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.powertop ];

    powerManagement.powertop = {
      enable = cfg.autotune;
      postStart = lib.concatLines cfg.postStart;
    };
  };
}
