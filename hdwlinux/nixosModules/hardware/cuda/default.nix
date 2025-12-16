{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.hardware.cuda;
in
{
  options.hdwlinux.hardware.cuda = {
    enable = config.lib.hdwlinux.mkEnableOption "cuda" "cuda";
  };

  config = lib.mkMerge [
    {
      hdwlinux.nix.extra-substituters = {
        "https://cache.nixos-cuda.org" =
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=";
      };
    }
    (lib.mkIf cfg.enable {
      nixpkgs.config.cudaSupport = true;
    })
  ];
}
