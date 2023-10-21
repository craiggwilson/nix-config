{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.steam;
in
{
  options.hdwlinux.features.steam = with types; {
    enable = mkBoolOpt false "Whether or not to enable steam.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      steam
    ];
  };
}
