{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.packages.scanning;
in
{
  options.hdwlinux.packages.scanning = with types; {
    enable = mkBoolOpt false "Whether or not to configure printing support.";
  };

  config = mkIf cfg.enable {
    hardware.sane = {
      enable = true;
      brscan5.enable = true;
    };

    hdwlinux.user.extraGroups = [
      "scanner" 
      "lp"
    ];
  };
}
