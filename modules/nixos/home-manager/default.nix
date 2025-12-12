{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.home-manager;
in
{
  options.hdwlinux.home-manager = {
    enable = config.lib.hdwlinux.mkEnableOption "home-manager" true;
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      backupFileExtension = ".bak";
      useUserPackages = true;
      useGlobalPkgs = true;
      verbose = true;
    };
  };
}
