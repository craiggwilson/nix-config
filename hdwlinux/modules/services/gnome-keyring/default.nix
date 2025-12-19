{
  config.substrate.modules.services.gnome-keyring = {
    tags = [ "gui" ];
    nixos = { pkgs, ... }: {
      services.gnome.gnome-keyring = {
        enable = true;
      };

      environment.systemPackages = [ pkgs.libsecret ];
    };
  };
}

