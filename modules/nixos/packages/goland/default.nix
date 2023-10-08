{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.goland;
in
{
  options.hdwlinux.packages.goland = with types; {
    enable = mkBoolOpt false "Whether or not to enable goland.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      jetbrains.goland
    ];
  };
}
