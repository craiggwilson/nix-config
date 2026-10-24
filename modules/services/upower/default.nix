{
  config.substrate.modules.services.upower = {
    tags = [ "role:laptop" ];
    nixos = {
      services.upower.enable = true;
    };
  };
}
