{
  config.substrate.modules.desktop.services.udiskie = {
    tags = [ "desktop" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Materialize this service's entry so `services.<name>` resolves even
        # when the central option leaves it unset; mkDefault keeps it
        # overridable from elsewhere.
        cfg = config.hdwlinux.desktop.services.udiskie;
        # Runtime tray selection: Noctalia provides its own mount UI (the
        # aristides/udiskie widget), so suppress the tray icon there; every
        # other shell shows it. Mirrors the action commandOverride pattern but
        # is resolved from $HDWLINUX_SHELL at runtime rather than at eval.
        trayOverrides = {
          noctalia = "--no-tray";
        };
        # Run in every shell except those opted out via enableOverride.
        shellGating = lib.mapAttrsToList (shell: _enabled: "!HDWLINUX_SHELL=${shell}") (
          lib.filterAttrs (_: enabled: !enabled) cfg.enableOverride
        );
        wrapper = pkgs.writeShellScript "udiskie" ''
          set -eu
          tray="--smart-tray"
          case "''${HDWLINUX_SHELL:-}" in
          ${lib.concatStrings (lib.mapAttrsToList (shell: flag: "${shell}) tray=${flag} ;;\n") trayOverrides)}
          esac
          exec ${pkgs.udiskie}/bin/udiskie --automount "$tray"
        '';
      in
      lib.mkMerge [
        # Seed this service's entry with mkDefault so `services.<name>` exists
        # whenever this module is enabled, while staying overridable.
        {
          hdwlinux.desktop.services.udiskie = lib.mkDefault {
            enable = true;
            enableOverride = { };
          };
        }
        (lib.mkIf cfg.enable {
          systemd.user.services.udiskie = {
            Unit = {
              Description = "Disks automounter";
              Documentation = [ "https://github.com/cdown/udiskie" ];
              After = [ "graphical-session-pre.target" ];
              PartOf = [ "graphical-session.target" ];
              ConditionEnvironment = shellGating;
            };

            Service = {
              Type = "simple";
              ExecStart = wrapper;
              Restart = "on-failure";
            };

            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };
        })
      ];
  };
}
