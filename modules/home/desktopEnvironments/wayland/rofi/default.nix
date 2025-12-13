{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopEnvironments.wayland.rofi;
in
{
  options.hdwlinux.desktopEnvironments.wayland.rofi = {
    # TODO: for whatever reason, using config here causes infinite recursion, but only if config.programs.rofi.enable = true.
    enable = lib.hdwlinux.mkEnableOption "rofi" true;
  };

  config = lib.mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi;
      cycle = true;
      theme = "theme.rasi";
      extraConfig = {
        "show-icons" = true;
        "display-drun" = "";
        "display-run" = "";
        "display-filebrowser" = "";
        "display-power-menu" = "󰐥";
        "display-hyprland-keybinds" = "⌨";
        "display-window" = "";
        "drun-display-format" = "{name}";
        "window-format" = "{w} · {c} · {t}";
        "modes" = "window,drun";
      };
    };

    xdg.configFile."rofi/colors.rasi".text = lib.mkIf config.hdwlinux.theme.enable ''
      * {
          background:     ${config.hdwlinux.theme.colors.withHashtag.base00};
          background-alt: ${config.hdwlinux.theme.colors.withHashtag.base01};
          foreground:     ${config.hdwlinux.theme.colors.withHashtag.base05};
          selected:       ${config.hdwlinux.theme.colors.withHashtag.base07};
          active:         ${config.hdwlinux.theme.colors.withHashtag.base06};
          urgent:         ${config.hdwlinux.theme.colors.withHashtag.base0E};

          base00: ${config.hdwlinux.theme.colors.withHashtag.base00};
          base01: ${config.hdwlinux.theme.colors.withHashtag.base01};
          base02: ${config.hdwlinux.theme.colors.withHashtag.base02};
          base03: ${config.hdwlinux.theme.colors.withHashtag.base03};
          base04: ${config.hdwlinux.theme.colors.withHashtag.base04};
          base05: ${config.hdwlinux.theme.colors.withHashtag.base05};
          base06: ${config.hdwlinux.theme.colors.withHashtag.base06};
          base07: ${config.hdwlinux.theme.colors.withHashtag.base07};
          base08: ${config.hdwlinux.theme.colors.withHashtag.base08};
          base09: ${config.hdwlinux.theme.colors.withHashtag.base09};
          base0A: ${config.hdwlinux.theme.colors.withHashtag.base0A};
          base0B: ${config.hdwlinux.theme.colors.withHashtag.base0B};
          base0C: ${config.hdwlinux.theme.colors.withHashtag.base0C};
          base0D: ${config.hdwlinux.theme.colors.withHashtag.base0D};
          base0E: ${config.hdwlinux.theme.colors.withHashtag.base0E};
          base0F: ${config.hdwlinux.theme.colors.withHashtag.base0F};
      }
    '';

    xdg.configFile."rofi/theme.rasi".source =
      config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/home/desktopEnvironments/wayland/rofi/theme.rasi";
  };
}
