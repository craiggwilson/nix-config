{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.hardware.xone;
in
{
  options.hdwlinux.hardware.xone = {
    enable = lib.mkOption {
      description = "Whether to enable xone.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "gaming" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.xone.enable = true;
  };
}
