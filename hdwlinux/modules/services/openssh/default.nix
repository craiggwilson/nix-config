{
  config.substrate.modules.services.openssh = {
    nixos = {
      services.openssh = {
        enable = true;
        settings.X11Forwarding = false;
        settings.PasswordAuthentication = false;
        settings.KbdInteractiveAuthentication = false;
      };
    };
  };
}

