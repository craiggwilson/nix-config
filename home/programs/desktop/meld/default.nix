{ pkgs, ... }: {
    home.packages = with pkgs; [
      meld
    ];
}
