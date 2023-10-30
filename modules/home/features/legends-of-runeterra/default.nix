{ options, config, lib, pkgs, inputs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.legends-of-runeterra;
in
{
  options.hdwlinux.features.legends-of-runeterra = with types; {
    enable = mkBoolOpt false "Whether or not to enable legends-of-runeterra.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    #inputs.nix-gaming.packages.${pkgs.system}.dxvk
    hdwlinux.legends-of-runeterra
  ];
}
