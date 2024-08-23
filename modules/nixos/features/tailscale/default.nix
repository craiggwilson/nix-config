{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.tailscale;
in
{
  options.hdwlinux.features.tailscale = {
    enable = mkBoolOpt false "Whether or not to enable support for tailscale.";
    exitNode = mkStrOpt "" "The exit node to use.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ tailscale ];

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "none";
    };

    programs.bash.shellAliases =
      let
        suffix = if cfg.exitNode != "" then " --exit-node ${cfg.exitNode}" else "";
      in
      {
        ts = "tailscale";
        ts-up = "sudo tailscale up${suffix}";
        ts-down = "sudo tailscale down";
      };
  };
}
