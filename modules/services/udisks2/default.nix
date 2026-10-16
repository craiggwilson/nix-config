{
  config.substrate.modules.services.udisks2 = {
    provides = [ "hardware:storage" ];

    nixos = {
      services.udisks2.enable = true;
    };
  };
}
