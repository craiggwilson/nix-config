{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.reaper;
in
{
  options.hdwlinux.features.reaper = with types; {
    enable = mkEnableOpt ["audio:production" "gui"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      reaper
      qpwgraph

      # plugins
      distrho
      calf
      eq10q
      helm
      lsp-plugins
      x42-plugins
      x42-gmsynth
      dragonfly-reverb
      guitarix
      FIL-plugins
      geonkick
      sfizz

      # windows plugin bridge
      yabridge
      yabridgectl
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
