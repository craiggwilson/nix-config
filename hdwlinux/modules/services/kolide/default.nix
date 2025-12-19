{
  config.substrate.modules.services.kolide = {
    tags = [ "users:craig:work" ];
    nixos = {
      services.kolide-launcher.enable = true;
    };
  };
}

