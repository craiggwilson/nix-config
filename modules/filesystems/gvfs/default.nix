{
  config.substrate.modules.filesystems.gvfs = {
    provides = [
      "filesystem:gvfs"
      "hardware:storage"
    ];
    nixos = {
      services.gvfs.enable = true;
    };
  };
}
