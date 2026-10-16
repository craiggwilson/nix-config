{
  config.substrate.modules.hardware.xone = {
    provides = [ "hardware:xone" "gaming" ];
    tags = [ "gaming" ];
    nixos = {
      hardware.xone.enable = true;
    };
  };
}
