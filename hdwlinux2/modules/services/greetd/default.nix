{
  config.substrate.modules.services.greetd = {
    nixos = { pkgs, ... }:
      let
        cmd = "uwsm start default";
      in
      {
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --remember --remember-session --time --cmd \"${cmd}\"";
              user = "greeter";
            };
          };
        };

        security.pam.services.greetd.enableGnomeKeyring = true;
      };
  };
}

