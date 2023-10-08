{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.hyprpicker;
in
{
  options.hdwlinux.packages.hyprpicker = with types; {
    enable = mkBoolOpt false "Whether or not to enable hyprpicker.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      hyprpicker      
    ];
  };
}
