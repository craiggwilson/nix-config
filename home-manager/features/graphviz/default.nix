{ pkgs, ... }: {
    home.packages = with pkgs; [
        graphviz
    ];
}