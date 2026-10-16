{
  config.substrate.modules.services.fwupd = {
    provides = [ "hardware:firmware" ];

    nixos = {
      services.fwupd.enable = true;
    };
  };
}
