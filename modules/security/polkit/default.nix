{
  config.substrate.modules.security.polkit = {
    provides = [ "core:session" ];

    nixos = {
      security.polkit.enable = true;
    };
  };
}
