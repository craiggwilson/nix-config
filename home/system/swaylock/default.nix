{ config, repoDirectory, ... }: {
    home.file."${config.xdg.configHome}/swaylock/config".source = config.lib.file.mkOutOfStoreSymlink "${repoDirectory}/home/system/swaylock/config/config";
}
