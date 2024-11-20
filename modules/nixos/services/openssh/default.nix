{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.openssh;
in
{
  options.hdwlinux.services.openssh = {
    enable = lib.hdwlinux.mkBoolOpt true "Enable OpenSSH feature.";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;

      settings.X11Forwarding = true;

      # Require public key authentication
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
  };
}
