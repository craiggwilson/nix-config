{
  config.substrate.modules.services.gnome-keyring = {
    tags = [ "desktop" ];
    nixos = { pkgs, ... }: {
      services.gnome.gnome-keyring = {
        enable = true;
      };

      environment.systemPackages = [ pkgs.libsecret ];
    };
  };
}
