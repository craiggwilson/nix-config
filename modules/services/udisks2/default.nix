{
  config.substrate.modules.services.udisks2 = {
    provides = [ "services:udisks2" "hardware:storage" ];

    nixos = {
      services.udisks2.enable = true;
    };
  };
}
