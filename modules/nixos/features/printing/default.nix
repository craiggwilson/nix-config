{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.printing;
in
{
  options.hdwlinux.features.printing = with types; {
    enable = mkBoolOpt false "Whether or not to configure printing support.";
  };

  config.services.printing = mkIf cfg.enable {
    enable = true;
    webInterface = false;
  };
}
