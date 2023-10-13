{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.dunst;
in
{
  options.hdwlinux.packages.dunst = with types; {
    enable = mkBoolOpt false "Whether or not to enable dunst.";
    extraConfig = mkOpt lines "" "Extra settings to add to the dunstrc file.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        dunst
    ];

    hdwlinux.home.configFile."dunst/dunstrc".text = cfg.extraConfig;
  };
}
