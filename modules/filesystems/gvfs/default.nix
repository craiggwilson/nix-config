{
  config.substrate.modules.filesystems.gvfs = {
    nixos = {
      services.gvfs.enable = true;
    };
  };
}
