{
  config.substrate.modules.hardware.redistributableFirmware = {
    nixos = {
      hardware.enableRedistributableFirmware = true;
    };
  };
}

