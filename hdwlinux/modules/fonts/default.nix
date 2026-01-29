{
  config.substrate.modules.fonts = {
    tags = [ "gui" ];
    nixos = { pkgs, ... }: {
      fonts = {
        packages = [
          pkgs.nerd-fonts.droid-sans-mono
          pkgs.nerd-fonts.dejavu-sans-mono
          pkgs.nerd-fonts.fira-code
          pkgs.noto-fonts-color-emoji
          pkgs.comic-mono
        ];

        fontconfig = {
          enable = true;
          defaultFonts = {
            emoji = [ "Noto Color Emoji" ];
            monospace = [ "FiraCode Nerd Font Mono" ];
            sansSerif = [ "FiraCode Nerd Font" ];
            serif = [ "FiraCode Nerd Font" ];
          };
        };
      };
    };
  };
}

