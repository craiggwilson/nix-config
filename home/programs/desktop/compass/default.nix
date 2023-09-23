{ pkgs, ... }: {
    home.packages = with pkgs; [
        mongodb-compass
    ];
}