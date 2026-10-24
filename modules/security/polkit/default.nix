{
  config.substrate.modules.security.polkit = {
    tags = [ "core:security" ];
    nixos = {
      security.polkit.enable = true;
    };
  };
}
