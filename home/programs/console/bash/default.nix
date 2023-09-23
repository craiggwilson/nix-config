{ ... }: {
    home.file.".bashrc.d/funcs.sh".source = ./config/funcs.sh;

    programs.bash = {
        enable = true;
        enableVteIntegration = true;
        historyControl = [
            "ignoredups"
            "ignorespace"
        ];
        historyIgnore = [
            "cd"
            "exit"
            "ls"
        ];
        initExtra = ''
            source "$HOME/.bashrc.d/funcs.sh"
            # [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        '';
    };
}
