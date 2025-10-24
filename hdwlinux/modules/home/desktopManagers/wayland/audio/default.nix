{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.audio;
in
{
  options.hdwlinux.desktopManagers.wayland.audio = {
    enable = lib.hdwlinux.mkEnableOption "audio" config.hdwlinux.desktopManagers.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
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
}
