{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.virtualization.waydroid;
in
{
  options.hdwlinux.virtualization.waydroid = {
    enable = lib.mkOption {
      description = "Whether to enable waydroid.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "virtualization:waydroid" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
  };
}
