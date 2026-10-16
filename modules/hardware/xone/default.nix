{
  config.substrate.modules.hardware.xone = {
    provides = [ "gaming" ];
    tags = [ "gaming" ];
    nixos = {
      hardware.xone.enable = true;
    };
  };
}
