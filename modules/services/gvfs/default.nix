{
  config.substrate.modules.services.gvfs = {
    tags = [ "desktop" ];
    nixos = {
      services.gvfs.enable = true;
    };
  };
}
