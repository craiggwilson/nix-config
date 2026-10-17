{
  config.substrate.modules.hardware.bluetooth = {
    provides = [ "hardware:bluetooth" ];
    nixos = {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    };
  };
}
