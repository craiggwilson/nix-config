{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.swaylock;
in
{
  options.hdwlinux.packages.swaylock = with types; {
    enable = mkBoolOpt false "Whether or not to enable swaylock.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.swaylock = {
      enable = true;
      settings = {
        ignore-empty-password = false;
        line-uses-ring = true;
        indicator-radius = 100;
        indicator-thickness = 10;
      };
    };

    security.pam.services.swaylock.text = ''
      auth sufficient pam_unix.so try_first_pass likeauth nullok
      auth sufficient pam_fprintd.so
      auth include login
    '';
  };
}
