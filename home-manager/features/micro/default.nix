{ pkgs, ... }: {
    programs.micro = {
        enable = true;
        settings = {
            mkparents = true;
        };
    };

    home.sessionVariables = {
        EDITOR = "micro";
        VISUAL = "micro";
    };
}
