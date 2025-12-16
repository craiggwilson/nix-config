{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.security.pam;
in
{
  options.hdwlinux.security.pam = {
    enable = lib.hdwlinux.mkEnableOption "pam" true;
  };

  config = lib.mkIf cfg.enable {
    # TODO: figure out how to get this into userland...
    security.pam.services.hyprlock.text = ''
      auth sufficient pam_unix.so try_first_pass likeauth nullok
      auth sufficient pam_fprintd.so
      auth include login
    '';
  };
}
