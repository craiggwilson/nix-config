{
  config.substrate.modules.desktop.custom.audioctl = {
    tags = [ "desktop:custom" "audio" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
            name = "audioctl";
            runtimeInputs = [
              pkgs.pavucontrol
              pkgs.wireplumber
            ];
            subcommands = {
              input = {
                mute = {
                  off = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0";
                  on = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1";
                  toggle = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
                };
                volume = {
                  lower = "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-";
                  raise = "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%+ --limit 1";
                };
                show-menu = "pavucontrol -t 4";
              };
              output = {
                mute = {
                  off = "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0";
                  on = "wpctl set-mute @DEFAULT_AUDIO_SINK@ 1";
                  toggle = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                };
                volume = {
                  lower = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
                  raise = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1";
                };
                show-menu = "pavucontrol -t 3";
              };
            };
          })
        ];
      };
  };
}

