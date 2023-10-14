{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.swaylock;
in
{
  options.hdwlinux.packages.swaylock = with types; {
    enable = mkBoolOpt false "Whether or not to enable swaylock.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.swaylock = {
      enable = true;
      settings = {
        ignore-empty-password = true;
        image = "${config.hdwlinux.theme.wallpaper1}";
        color = "${config.hdwlinux.theme.color0}";

        bs-hl-color = "${config.hdwlinux.theme.color15}";
        caps-lock-bs-hl-color = "${config.hdwlinux.theme.color12}";
        caps-lock-key-hl-color = "${config.hdwlinux.theme.color13}";

        indicator-radius = 100;
        indicator-thickness = 10;

        inside-color = "${config.hdwlinux.theme.color0}";
        inside-clear-color = "${config.hdwlinux.theme.color9}";
        inside-ver-color = "${config.hdwlinux.theme.color10}";
        inside-wrong-color = "${config.hdwlinux.theme.color11}";

        key-hl-color = "${config.hdwlinux.theme.color14}";

        layout-bg-color = "${config.hdwlinux.theme.color0}";

        line-uses-ring = true;

        ring-color = "${config.hdwlinux.theme.color1}";
        ring-clear-color = "${config.hdwlinux.theme.color8}";
        ring-ver-color = "${config.hdwlinux.theme.color9}";
        ring-wrong-color = "${config.hdwlinux.theme.color12}";

        separator-color = "${config.hdwlinux.theme.color1}";

        text-color = "${config.hdwlinux.theme.color6}";
        text-clear-color = "${config.hdwlinux.theme.color1}";
        text-ver-color = "${config.hdwlinux.theme.color1}";
        text-wrong-color = "${config.hdwlinux.theme.color1}";
      };
    };

    security.pam.services.swaylock = { }; # "auth include login";
  };
}
