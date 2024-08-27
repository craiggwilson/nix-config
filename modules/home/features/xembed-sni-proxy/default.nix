{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.xembed-sni-proxy;
in
{
  options.hdwlinux.features.xembed-sni-proxy = with types; {
    enable = mkEnableOpt [
      "gui"
    ] config.hdwlinux.features.tags;
  };

  config.services.xembed-sni-proxy = mkIf cfg.enable { enable = true; };
}
