{
  config.substrate.modules.filesystems.gvfs = {
    provides = [ "filesystems:gvfs" "hardware:storage" ];
    nixos = {
      services.gvfs.enable = true;
    };
  };
}
