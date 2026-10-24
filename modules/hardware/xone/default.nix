{
  config.substrate.modules.hardware.xone = {
    tags = [ "capability:gaming-controller" ];
    nixos = {
      hardware.xone.enable = true;
    };
  };
}
