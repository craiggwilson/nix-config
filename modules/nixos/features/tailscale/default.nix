{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.tailscale; 
in
{
  options.hdwlinux.features.tailscale = {
    enable = mkBoolOpt false "Whether or not to enable support for tailscale.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      tailscale
    ];

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "none";
    };

    programs.bash.shellAliases = {
      ts = "tailscale";
      "ts-up" = "sudo tailscale up --exit-node synology";
      "ts-down" = "sudp tailscale down";
    };
  };
}