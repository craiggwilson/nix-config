{
  config.substrate.modules.hardware.thunderbolt = {
    tags = [ "thunderbolt" ];
    nixos = {
      boot.initrd.availableKernelModules = [ "thunderbolt" ];
      services.hardware.bolt.enable = true;
    };
  };
}

