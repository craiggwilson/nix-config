{ config, pkgs, lib, ... }: {
  services.openssh = {
    enable = true;
    # Require public key authentication
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };
}