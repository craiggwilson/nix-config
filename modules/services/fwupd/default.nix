{
  config.substrate.modules.services.fwupd = {
    provides = [ "services:fwupd" "hardware:firmware" ];

    nixos = {
      services.fwupd.enable = true;
    };
  };
}
