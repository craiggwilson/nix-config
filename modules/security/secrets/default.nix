_:
let
  hostTokenRoot = "/etc/secretspec";
in
{
  config.substrate.modules.security.secrets = {
    tags = [ "security:secrets" ];

    nixos =
      { pkgs, ... }:
      {
        config.secretspec = {
          providers.onepassword = {
            uri = "onepassword://";

            # secretspec shells out to op, so the CLI belongs to the provider.
            package = pkgs._1password-cli;

            # Convention address: /etc/secretspec/<hostname>/_provider/service_account_token
            credentials.service_account_token = "file:${hostTokenRoot}";
          };
          defaultProviders = [ "onepassword" ];
        };

        # Root-only, so a token placed under it is unreadable by user units.
        config.systemd.tmpfiles.rules = [ "d ${hostTokenRoot} 0700 root root -" ];
      };

    homeManager =
      { pkgs, config, ... }:
      {
        config.secretspec = {
          providers.onepassword = {
            uri = "onepassword://";

            # secretspec shells out to op, so the CLI belongs to the provider.
            package = pkgs._1password-cli;

            # Convention address: <configHome>/secretspec/<user>/_provider/service_account_token
            credentials.service_account_token = "file:${config.xdg.configHome}/secretspec";
          };
          defaultProviders = [ "onepassword" ];
        };
      };
  };
}
