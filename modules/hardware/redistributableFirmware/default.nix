{
  config.substrate.modules.hardware.redistributableFirmware = {
    tags = [ "capability:firmware" ];
    nixos = {
      hardware.enableRedistributableFirmware = true;
    };
  };
}
