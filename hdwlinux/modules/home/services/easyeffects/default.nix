{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.services.easyeffects;
in
{

  options.hdwlinux.services.easyeffects = {
    enable = config.lib.hdwlinux.mkEnableOption "easyeffects" "audio";

  };

  config = lib.mkIf cfg.enable {
    services.easyeffects = {
      enable = true;
    };
  };
}
