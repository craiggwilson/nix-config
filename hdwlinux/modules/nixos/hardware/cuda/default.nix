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
        "https://cuda-maintainers.cachix.org" = {
          key = "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=";
        };
      };
    }
    (lib.mkIf cfg.enable {
      nixpkgs.config.cudaSupport = true;
    })
  ];
}
