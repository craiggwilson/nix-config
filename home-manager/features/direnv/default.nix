{ pkgs, ... }: {
    programs.direnv = {
        enable = true;
        enableBashIntegration = true;
        config = {
            global.load_dotenv = true;
        };
    };
}