{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.dunst;
in
{
  options.hdwlinux.packages.dunst = with types; {
    enable = mkBoolOpt false "Whether or not to enable dunst.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        dunst
    ];

    hdwlinux.home.configFile."dunst/dunstrc".text = ''
      [global]
        frame_color = "#${config.hdwlinux.theme.color5}"
        separator_color = "#${config.hdwlinux.theme.color5}"

      [base16_low]
        msg_urgency = low
        background = "#${config.hdwlinux.theme.color1}"
        foreground = "#${config.hdwlinux.theme.color3}"

      [base16_normal]
        msg_urgency = normal
        background = "#${config.hdwlinux.theme.color2}"
        foreground = "#${config.hdwlinux.theme.color5}"

      [base16_critical]
        msg_urgency = critical
        background = "#${config.hdwlinux.theme.color11}"
        foreground = "#${config.hdwlinux.theme.color6}"
    '';
  };
}
