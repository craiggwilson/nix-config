{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.obs-studio;
in
{
  options.hdwlinux.programs.obs-studio = {
    enable = config.lib.hdwlinux.mkEnableOption "obs-studio" [
      "gui"
      "video:production"
    ];
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [ droidcam-obs ];
    };
  };
}
