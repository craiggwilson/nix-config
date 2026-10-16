{
  config.substrate.modules.services.gnome-keyring = {
    provides = [ "gui" ];
    tags = [ "gui" ];
    nixos = { pkgs, ... }: {
      services.gnome.gnome-keyring = {
        enable = true;
      };

      environment.systemPackages = [ pkgs.libsecret ];
    };
  };
}
