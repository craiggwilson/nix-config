{
  config.substrate.modules.programs.maskedemail = {
    tags = [ "profile:email-management" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        wrap,
        ...
      }:
      let
        cfg = config.hdwlinux.programs.maskedemail;

        maskedemail =
          if cfg.tokenFile == null then
            pkgs.hdwlinux.maskedemail-cli
          else
            wrap.package {
              package = pkgs.hdwlinux.maskedemail-cli;
              preHook = ''
                tokenFile=${lib.escapeShellArg cfg.tokenFile}
                if [[ ! -s "$tokenFile" ]]; then
                  echo "maskedemail-cli: token file $tokenFile is missing or empty" >&2
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
        options.hdwlinux.programs.maskedemail.tokenFile = lib.mkOption {
          default = null;
          description = "Path to the file containing the masked-email API token; null uses the unwrapped CLI.";
          type = lib.types.nullOr lib.types.str;
        };

        config.home.packages = [
          maskedemail
          maskedemailNew
        ];
      };
  };
}
