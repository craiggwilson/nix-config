{ config, repoDirectory, ... }: {
    home.file."${config.xdg.configHome}/hypr/hyprpaper.conf".source = config.lib.file.mkOutOfStoreSymlink "${repoDirectory}/home/system/hyprpaper/config/hyprpaper.conf";
    home.file."${config.xdg.configHome}/hypr/wallpaper.jpg".source = config.lib.file.mkOutOfStoreSymlink "${repoDirectory}/home/system/hyprpaper/config/wallpaper.jpg";
}
