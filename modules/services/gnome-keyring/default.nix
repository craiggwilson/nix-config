{
  config.substrate.modules.services.gnome-keyring = {
    provides = [ "services:gnome-keyring" "gui" ];
    tags = [ "gui" ];
    nixos = { pkgs, ... }: {
      services.gnome.gnome-keyring = {
        enable = true;
      };

      environment.systemPackages = [ pkgs.libsecret ];
    };
  };
}
