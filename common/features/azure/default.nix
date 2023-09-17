{ pkgs, ... }: {
    home.packages = with pkgs; [
        pkgs.azure-cli
    ];
}