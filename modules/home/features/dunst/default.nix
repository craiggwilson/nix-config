{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.dunst;
in
{
  options.hdwlinux.features.dunst = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ dunst ];

    xdg.configFile."dunst/dunstrc".text = lib.mkIf config.hdwlinux.theme.enable ''
      [global]
        frame_color = "${config.hdwlinux.theme.colors.withHashtag.base05}"
        separator_color = "${config.hdwlinux.theme.colors.withHashtag.base05}"

      [base16_low]
        msg_urgency = low
        background = "${config.hdwlinux.theme.colors.withHashtag.base01}"
        foreground = "${config.hdwlinux.theme.colors.withHashtag.base03}"

      [base16_normal]
        msg_urgency = normal
        background = "${config.hdwlinux.theme.colors.withHashtag.base02}"
        foreground = "${config.hdwlinux.theme.colors.withHashtag.base05}"

      [base16_critical]
        msg_urgency = critical
        background = "${config.hdwlinux.theme.colors.withHashtag.base0B}"
        foreground = "${config.hdwlinux.theme.colors.withHashtag.base06}"
    '';
  };
}
