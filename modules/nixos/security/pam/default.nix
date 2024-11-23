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
    enable = lib.mkOption {
      description = "Whether to enable pam.";
      type = lib.types.bool;
      default = true;
    };
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
