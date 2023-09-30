{ config, repoDirectory, ... }: {
    home.file."${config.xdg.configHome}/hypr/hyprland.conf".source = config.lib.file.mkOutOfStoreSymlink "${repoDirectory}/home/system/hyprland/config/hyprland.conf";
}
