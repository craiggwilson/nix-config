{
  config.substrate.modules.hardware.redistributableFirmware = {
    provides = [ "hardware:firmware" ];
    nixos = {
      hardware.enableRedistributableFirmware = true;
    };
  };
}
