{
  config.substrate.modules.programs.reaper = {
    tags = [
      "audio:production"
      "gui"
    ];

    homeManager =
      { config, pkgs, ... }:
      {
        home.packages = [
          pkgs.reaper
          pkgs.qpwgraph
          pkgs.calf
          pkgs.eq10q
          pkgs.helm
          pkgs.lsp-plugins
          pkgs.x42-plugins
          pkgs.x42-gmsynth
          pkgs.dragonfly-reverb
          pkgs.guitarix
          pkgs.fil-plugins
          pkgs.sfizz
          pkgs.yabridge
          pkgs.yabridgectl
        ];

        home.file.".config/yabridgectl/config.toml".text = ''
          plugin_dirs = ['${config.home.homeDirectory}/.win-vst']
          vst2_location = 'centralized'
          no_verify = false
          blacklist = []
        '';
      };
  };
}

