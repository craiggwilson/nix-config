{
  config.substrate.modules.programs.ghostty = {
    tags = [ "gui" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        hdwlinux.app.terminal = lib.mkDefault {
          package = config.programs.ghostty.package;
          desktopName = "ghostty.desktop";
        };

        programs.ghostty = {
          enable = true;
          package = pkgs.ghostty;
          enableBashIntegration = config.programs.bash.enable;
          enableZshIntegration = config.programs.zsh.enable;

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
              "ctrl+shift=left=csi:1;6D"
              "ctrl+shift=right=csi:1;6C"
            ];
          };
        };
      };
  };
}
