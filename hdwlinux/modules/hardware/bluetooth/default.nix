{
  config.substrate.modules.hardware.bluetooth = {
    tags = [ "bluetooth" ];
    nixos = {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    };
  };
}

