{
  config.substrate.modules.services.greetd = {
    tags = [ "desktop" ];
    nixos =
      { pkgs, ... }:
      {
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --sessions /run/current-system/sw/share/greetd-sessions --remember --remember-session --time";
              user = "greeter";
            };
          };
        };

        security.pam.services.greetd.enableGnomeKeyring = true;
      };
  };
}
