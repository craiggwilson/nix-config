{ config, repoDirectory, ... }: {
    home.file."${config.xdg.configHome}/waybar/config.jsonc".source = config.lib.file.mkOutOfStoreSymlink "${repoDirectory}/home/system/waybar/config/config.jsonc";
    home.file."${config.xdg.configHome}/waybar/style.css".source = config.lib.file.mkOutOfStoreSymlink "${repoDirectory}/home/system/waybar/config/style.css";
}
