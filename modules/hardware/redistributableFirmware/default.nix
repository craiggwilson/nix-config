{
  config.substrate.modules.hardware.redistributableFirmware = {
    provides = [
      "hardware:redistributableFirmware"
      "hardware:firmware"
    ];
    nixos = {
      hardware.enableRedistributableFirmware = true;
    };
  };
}
