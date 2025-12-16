{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.services.playerctld;
in
{

  options.hdwlinux.services.playerctld = {
    enable = config.lib.hdwlinux.mkEnableOption "playerctld" "audio";

  };

  config = lib.mkIf cfg.enable {
    services.playerctld = {
      enable = true;
    };
  };
}
