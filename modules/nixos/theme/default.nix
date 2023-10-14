{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.theme;
in {
  options.hdwlinux.theme = with types; {
    wallpaper1 = mkOption {
      type = path;
      description = "Wallpaper for monitor 1.";
    };

    wallpaper2 = mkOption {
      type = path;
      description = "Wallpaper for monitor 2.";
    };

    wallpaper3 = mkOption {
      type = path;
      description = "Wallpaper for monitor 3.";
    };
  };

  config = {
    stylix = {
      image = cfg.wallpaper1;
      polarity = "dark";
      autoEnable = true;
    };

    hdwlinux.home.extraOptions.stylix.targets = {
      # kitty.enable = true;
      # gtk.enable = true;
      # swaylock.enable = true;
      # vscode.enable = true;
      waybar.enable = false;
    };
  };
}
