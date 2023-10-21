{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.dunst;
in
{
  options.hdwlinux.features.dunst = with types; {
    enable = mkBoolOpt false "Whether or not to enable dunst.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        dunst
    ];

    hdwlinux.home.configFile."dunst/dunstrc".text = ''
      [global]
        frame_color = "${config.lib.stylix.colors.withHashtag.base05}"
        separator_color = "${config.lib.stylix.colors.withHashtag.base05}"

      [base16_low]
        msg_urgency = low
        background = "${config.lib.stylix.colors.withHashtag.base01}"
        foreground = "${config.lib.stylix.colors.withHashtag.base03}"

      [base16_normal]
        msg_urgency = normal
        background = "${config.lib.stylix.colors.withHashtag.base02}"
        foreground = "${config.lib.stylix.colors.withHashtag.base05}"

      [base16_critical]
        msg_urgency = critical
        background = "${config.lib.stylix.colors.withHashtag.base0B}"
        foreground = "${config.lib.stylix.colors.withHashtag.base06}"
    '';
  };
}
