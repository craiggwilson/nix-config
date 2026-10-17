{
  config.substrate.modules.hardware.xone = {
    provides = [
      "hardware:xone"
      "gaming"
    ];
    nixos = {
      hardware.xone.enable = true;
    };
  };
}
