{
  config.substrate.modules.services._1password = {
    tags = [ "security:passwordmanager" ];

    nixos =
      {
        lib,
        hasTag,
        ...
      }:
      {
        programs._1password.enable = true;

        programs._1password-gui = lib.mkIf (hasTag "gui") {
          enable = true;
        };

        security.pam.services."1password".enableGnomeKeyring = hasTag "gui";

        # Zen isn't on 1Password's trusted-browser whitelist, so the
        # BrowserSupport setgid wrapper rejects it with UnknownBrowser and the
        # extension shows a "Something went wrong" page. Listing the browser's
        # binary name here is 1Password's documented workaround for
        # unofficially supported browsers; inert wherever zen isn't installed.
        #
        # The helper verifies by the basename of the browser's real executable
        # (/proc/<pid>/exe), which under nixpkgs' wrapper is the unwrapped ELF
        # (lib/zen-bin-*/zen), not the `zen-beta` wrapper script — so both
        # names are listed.
        environment.etc."1password/custom_allowed_browsers" = lib.mkIf (hasTag "gui") {
          text = ''
            zen
            zen-beta
          '';
          mode = "0755";
        };
      };

    homeManager =
      {
        hasTag,
        lib,
        pkgs,
        ...
      }:
      {
        hdwlinux.desktop.apps.passwordManager = lib.mkIf (hasTag "gui") (
          lib.mkDefault {
            package = pkgs._1password-gui;
          }
        );
        hdwlinux.desktop.apps.passwordManager-toggle = lib.mkIf (hasTag "gui") (
          lib.mkDefault {
            package = pkgs._1password-gui;
            args = [ "--toggle" ];
          }
        );
        hdwlinux.desktop.apps.passwordManager-lock = lib.mkIf (hasTag "gui") (
          lib.mkDefault {
            package = pkgs._1password-gui;
            args = [ "--lock" ];
          }
        );

        systemd.user.services."1password" = lib.mkIf (hasTag "gui") {
          Unit = {
            Description = "Password manager daemon";
            Documentation = [ "https://www.1password.com" ];
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Install = {
            WantedBy = [ "graphical-session-pre.target" ];
          };
          Service = {
            ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
            Restart = "always";
            RestartSec = "10";
          };
        };
      };
  };
}
