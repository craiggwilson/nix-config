{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.obs-studio;
in
{
  options.hdwlinux.features.obs-studio = with types; {
    enable = mkEnableOpt [
      "av"
      "gui"
    ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [ droidcam-obs ];
    };
  };
}
