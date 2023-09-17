{ pkgs, config, ... }: {
    programs.gh = {
        enable = true;
        extensions = [
            pkgs.gh-dash
        ];
    };

    home.file."${config.xdg.configHome}/gh-dash" = {
        source = ./config/gh-dash;
        recursive = true;
    };
}
