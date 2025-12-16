{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.raeford.networking;
in
{
  options.hdwlinux.raeford.networking = {
    enable = config.lib.hdwlinux.mkEnableOption "raeford office networking configuration" "raeford";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.networking.domain = lib.mkDefault "raeford.wilsonfamilyhq.com";
  };
}
