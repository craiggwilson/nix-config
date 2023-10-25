{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.pam;
in
{
  options.hdwlinux.features.pam = with types; {
    enable = mkBoolOpt false "Whether or not to enable pam.";
  };

  config = mkIf cfg.enable {
    security.pam.services.swaylock.text = ''
      auth sufficient pam_unix.so try_first_pass likeauth nullok
      auth sufficient pam_fprintd.so
      auth include login
    '';
  };
}
