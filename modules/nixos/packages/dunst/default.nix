{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.dunst;
in
{
  options.hdwlinux.packages.dunst = with types; {
    enable = mkBoolOpt false "Whether or not to enable dunst.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        dunst
    ];
  };
}
