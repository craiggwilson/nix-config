{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.scanning;
in
{
  options.hdwlinux.features.scanning = with types; {
    enable = mkBoolOpt false "Whether or not to configure printing support.";
  };

  config = mkIf cfg.enable {
    hardware.sane.enable = true;
    hardware.sane.extraBackends = with pkgs; [
      sane-airscan
    ];

    # TODO: move...
    # services.avahi = {
    #   enable = true;
    #   nssmdns = true;
    #   openFirewall = true;
    # };
  };
}
