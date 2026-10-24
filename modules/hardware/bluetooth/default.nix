{
  config.substrate.modules.hardware.bluetooth = {
    tags = [ "capability:bluetooth" ];
    nixos = {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    };
  };
}
