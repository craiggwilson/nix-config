{ pkgs, config, repoDirectory, ... }: {
    home.packages = with pkgs; [
        kubectl
        kubectx
    ];

    home.shellAliases = {
        k = "kubectl";
        kctx = "kubectx";
        kns = "kubens";
    };
}
