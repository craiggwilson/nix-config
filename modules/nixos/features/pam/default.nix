{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.pam;
in
{
  options.hdwlinux.features.pam = {
    enable = lib.hdwlinux.mkBoolOpt true "Enable pam feature.";
  };

  config = lib.mkIf cfg.enable {
    # TODO: figure out how to get this into userland...
    security.pam.services.hyprlock.text = ''
      auth sufficient pam_unix.so try_first_pass likeauth nullok
      auth sufficient pam_fprintd.so
      auth include login
    '';

    # TODO: figure out how to get this into userland...
    security.pam.services.swaylock.text = ''
      auth sufficient pam_unix.so try_first_pass likeauth nullok
      auth sufficient pam_fprintd.so
      auth include login
    '';
  };
}
