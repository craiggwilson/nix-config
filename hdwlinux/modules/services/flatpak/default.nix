{
  config.substrate.modules.services.flatpak = {
    tags = [ "gui" ];
    nixos = {
      xdg.portal.enable = true;

      services.flatpak = {
        enable = true;
        remotes = [
          {
            name = "flathub";
            location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          }
        ];
        packages = [ "com.github.tchx84.Flatseal" ];
        update.auto = {
          enable = true;
          onCalendar = "weekly";
        };
      };
    };
  };
}

