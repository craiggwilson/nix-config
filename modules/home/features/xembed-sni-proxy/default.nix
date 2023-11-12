{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.xembed-sni-proxy;
in
{
  options.hdwlinux.features.xembed-sni-proxy = with types; {
    enable = mkBoolOpt false "Whether or not to enable xembed-sni-proxy.";
  };

  config.services.xembed-sni-proxy = mkIf cfg.enable {
    enable = true;
  };
}
