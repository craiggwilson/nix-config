{ pkgs, ... }: {
    programs.exa = {
        enable = true;
        enableAliases = true;
        extraOptions = [
            "--group-directories-first"
            "--header"
        ];
        git = true;
    };
}