{
  config.substrate.modules.services.udisks2 = {
    tags = [ "desktop" ];
    nixos = {
      services.udisks2.enable = true;
    };
  };
}
