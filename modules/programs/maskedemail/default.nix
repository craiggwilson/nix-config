{
  config.substrate.modules.programs.maskedemail = {
    tags = [ "user:craig" ];

    homeManager =
      {
        pkgs,
        wrap,
        ...
      }:
      let
        maskedemail = wrap.package {
          package = pkgs.hdwlinux.maskedemail-cli;
          secrets.scope = "maskedemail";
        };

        maskedemailNew = pkgs.writeShellApplication {
          name = "maskedemail-new";
          runtimeInputs = [
            pkgs.wl-clipboard
            pkgs.libnotify
          ];
          text = ''
            set -euo pipefail
            addr=$(${maskedemail}/bin/maskedemail-cli create "$@")
            printf %s "$addr" | wl-copy
            notify-send "Masked email created" "$addr"
          '';
        };

      in
      {
        home.packages = [
          maskedemail
          maskedemailNew
        ];

        secretspec.entries.MASKEDEMAIL_TOKEN = {
          description = "Fastmail Masked Email API token for maskedemail-cli";
          ref = {
            vault = "Craig";
            item = "Fastmail";
            field = "maskedemail_token";
          };
        };

        secretspec.scopes.maskedemail.secrets = [ "MASKEDEMAIL_TOKEN" ];
      };
  };
}
