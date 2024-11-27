{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.filesystems.gvfs;
in
{
  options.hdwlinux.filesystems.gvfs = {
    enable = lib.hdwlinux.mkEnableOption "gvfs" true;
  };

  config = lib.mkIf cfg.enable {
    services.gvfs.enable = true;
  };
}
