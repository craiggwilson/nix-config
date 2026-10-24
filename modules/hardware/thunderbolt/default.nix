{
  config.substrate.modules.hardware.thunderbolt = {
    tags = [ "capability:thunderbolt" ];
    nixos = {
      boot.initrd.availableKernelModules = [ "thunderbolt" ];
      services.hardware.bolt.enable = true;
    };
  };
}
