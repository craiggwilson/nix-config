{
  config.substrate.modules.programs.maskedemail = {
    tags = [ "user:craig" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        wrap,
        ...
      }:
      let
        # Read the token from a file materialized once per login by
        # secretspec-materialize.service, rather than resolving it at exec
        # time: each secretspec resolution is an `op read` against
        # 1Password's daily read budget.
        tokenFile = config.secretspec.entries.MASKEDEMAIL_TOKEN.file.path;

        maskedemail = wrap.package {
          package = pkgs.hdwlinux.maskedemail-cli;
          preHook = ''
            tokenFile=${lib.escapeShellArg tokenFile}
            if [[ ! -s "$tokenFile" ]]; then
              echo "maskedemail-cli: token file $tokenFile is missing or empty; restart secretspec-materialize.service" >&2
              exit 1
            fi
            export MASKEDEMAIL_TOKEN="$(<"$tokenFile")"
          '';
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

          # Materialized to ~/.local/state/secretspec/files/MASKEDEMAIL_TOKEN
          # by the user oneshot; see the wrapper comment for why.
          file = { };
        };
      };
  };
}
