{
  config.substrate.modules.services.openssh = {
    provides = [ "core:ssh" ];

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
