{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.hyprpicker;
in
{
  options.hdwlinux.features.hyprpicker = with types; {
    enable = mkBoolOpt false "Whether or not to enable hyprpicker.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      hyprpicker      
    ];
  };
}
