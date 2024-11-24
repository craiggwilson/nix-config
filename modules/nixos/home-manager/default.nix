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
    enable = lib.hdwlinux.mkEnableOption "home-manager" true;
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      backupFileExtension = ".bak";
      extraSpecialArgs = {
        flake = config.hdwlinux.nix.flake;
      };
      useUserPackages = true;
      useGlobalPkgs = true;
      verbose = true;
    };
  };
}
