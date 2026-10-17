{
  config.substrate.modules.hardware.thunderbolt = {
    provides = [ "hardware:thunderbolt" ];
    nixos = {
      boot.initrd.availableKernelModules = [ "thunderbolt" ];
      services.hardware.bolt.enable = true;
    };
  };
}
