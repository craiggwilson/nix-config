{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.services.xembed-sni-proxy;
in
{
  options.hdwlinux.services.xembed-sni-proxy = {
    enable = config.lib.hdwlinux.mkEnableOption "xembed-sni-proxy" "gui";
  };

  config = lib.mkIf cfg.enable {
    services.xembed-sni-proxy = {
      enable = true;
    };
  };
}
