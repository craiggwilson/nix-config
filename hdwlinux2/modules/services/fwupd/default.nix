{
  config.substrate.modules.services.fwupd = {
    nixos = {
      services.fwupd.enable = true;
    };
  };
}

