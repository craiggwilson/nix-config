{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.tailscale;
in
{
  options.hdwlinux.features.tailscale = {
    enable = lib.hdwlinux.mkBoolOpt false "Whether or not to enable support for tailscale.";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ tailscale ];

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
  };
}
