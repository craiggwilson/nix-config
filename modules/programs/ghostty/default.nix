{
  config.substrate.modules.programs.ghostty = {
    tags = [ "gui" ];

    perUser =
      { config, lib, pkgs, ... }:
      let
        colors = config.hdwlinux.theme.colors.hexWithHashtag;

        # Byte-for-byte what HM used: pkgs.formats.keyValue with
        # listsAsDuplicateKeys and the " = " separator.
        keyValue = pkgs.formats.keyValue {
          listsAsDuplicateKeys = true;
          mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
        };

        settings = {
          theme = "hdwlinux";
          background-opacity = 0.88;
          background-opacity-cells = true;
          background-blur = true;
          gtk-titlebar = false;
          window-padding-x = 0;
          window-padding-y = 0;
          window-padding-balance = 0;
          font-family = "FiraCode Nerd Font Mono";
          font-size = 11;
          keybind = [
            "ctrl+v=paste_from_clipboard"
            "performable:ctrl+c=copy_to_clipboard"
            "ctrl+shift+left=csi:1;6D"
            "ctrl+shift+right=csi:1;6C"
          ];
        };

        themes.hdwlinux = {
          background = colors.base00;
          cursor-color = colors.base06;
          foreground = colors.base05;
          palette = [
            "0=${colors.base03}"
            "1=${colors.base08}"
            "2=${colors.base0B}"
            "3=${colors.base0A}"
            "4=${colors.base0D}"
            "5=${colors.base17}"
            "6=${colors.base0C}"
            "7=${colors.base05}"
            "8=${colors.base04}"
            "9=${colors.base08}"
            "10=${colors.base0B}"
            "11=${colors.base0A}"
            "12=${colors.base0D}"
            "13=${colors.base17}"
            "14=${colors.base0C}"
            "15=${colors.base07}"
          ];
          selection-background = colors.base02;
          selection-foreground = colors.base05;
        };
      in
      {
        packages = [ pkgs.ghostty ];

        hdwlinux.app.terminal = lib.mkDefault {
          package = pkgs.ghostty;
          desktopName = "ghostty.desktop";
        };

        files = {
          ".config/ghostty/config".source = keyValue.generate "ghostty-config" settings;
          ".config/ghostty/themes/hdwlinux".source = keyValue.generate "ghostty-hdwlinux-theme" themes.hdwlinux;
          # bat syntax highlighting for ghostty configs (HM's programs.ghostty
          # integration; the --map-syntax line lives in the bat module).
          ".config/bat/syntaxes/ghostty.sublime-syntax".source = "${pkgs.ghostty}/share/bat/syntaxes/ghostty.sublime-syntax";
        };

        hdwlinux.shell.zsh.initLines = [
          {
            prio = 440;
            text = ''
              if [[ -r "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration ]]; then
                source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
              fi
            '';
          }
        ];
        hdwlinux.shell.bash.initLines = [
          {
            prio = 480;
            text = ''
              if [[ -r "''${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash" ]]; then
                builtin source "''${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
              fi
            '';
          }
        ];
      };
  };
}
