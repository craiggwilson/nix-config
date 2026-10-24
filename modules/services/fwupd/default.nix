{
  config.substrate.modules.services.fwupd = {
    tags = [ "capability:firmware" ];
    nixos = {
      services.fwupd.enable = true;
    };
  };
}
