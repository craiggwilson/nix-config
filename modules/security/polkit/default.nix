{
  config.substrate.modules.security.polkit = {
    nixos = {
      security.polkit.enable = true;
    };
  };
}

