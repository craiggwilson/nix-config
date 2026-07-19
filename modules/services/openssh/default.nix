{
  config.substrate.modules.services.openssh = {
    nixos = {
      services.openssh = {
        enable = true;
        settings = {
          X11Forwarding = false;
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };
    };
  };
}
