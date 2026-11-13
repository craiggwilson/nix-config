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
        # dux-shell polls `maskedemail-cli list` about once a minute, so this
        # wrapper must not resolve its token at exec time: every secretspec
        # resolution is an `op read` billed against 1Password's account-wide
        # daily read budget (~1,000/day on a personal account), which the
        # poller alone exhausts — rate-limiting every other secretspec consumer
        # until the 24-hour window resets. The token is materialized once per
        # login/generation by secretspec-materialize.service instead, and read
        # from that file here: no provider round trip per poll.
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
