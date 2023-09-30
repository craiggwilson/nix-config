{ pkgs, ... }: {
    home.packages = with pkgs; [
        procps
    ];
}