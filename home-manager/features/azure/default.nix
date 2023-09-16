{ pkgsStable, ... }: {
    home.packages = with pkgsStable; [
        pkgsStable.azure-cli
    ];
}