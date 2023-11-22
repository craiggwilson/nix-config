{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.suites.services.core;
in
{
  options.hdwlinux.suites.services.core = with types; {
    enable = mkBoolOpt false "Whether or not to enable the core services.";
  };

  config = mkIf cfg.enable {
  	hdwlinux.features = {
      dconf.enable = true;
      openssh.enable = true;
      pam.enable = true;
      polkit.enable = true;
      udisks2.enable = true;
    };
  };
}
