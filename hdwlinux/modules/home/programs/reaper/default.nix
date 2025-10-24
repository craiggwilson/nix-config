{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.reaper;
in
{
  options.hdwlinux.programs.reaper = {
    enable = config.lib.hdwlinux.mkEnableOption "reaper" [
      "audio:production"
      "gui"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.reaper
      pkgs.qpwgraph

      # plugins
      pkgs.calf
      pkgs.eq10q
      pkgs.helm
      pkgs.lsp-plugins
      pkgs.x42-plugins
      pkgs.x42-gmsynth
      pkgs.dragonfly-reverb
      pkgs.guitarix
      pkgs.FIL-plugins
      #pkgs.geonkick
      pkgs.sfizz

      # windows plugin bridge
      pkgs.yabridge
      pkgs.yabridgectl
    ];

    # Setup Yabridge
    home.file = {
      ".config/yabridgectl/config.toml".text = ''
        plugin_dirs = ['${config.home.homeDirectory}/.win-vst']
        vst2_location = 'centralized'
        no_verify = false
        blacklist = []
      '';
    };
  };
}
