{
  config.substrate.modules.filesystems.gvfs = {
    provides = [ "hardware:storage" ];
    nixos = {
      services.gvfs.enable = true;
    };
  };
}
