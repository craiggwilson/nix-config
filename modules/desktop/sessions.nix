{
  config.substrate.modules.desktop.sessions = {
    tags = [ "desktop" ];

    generic =
      { lib, ... }:
      let
        compositorType = lib.types.submodule {
          options = {
            command = lib.mkOption { type = lib.types.str; };
            comment = lib.mkOption { type = lib.types.str; };
            desktopName = lib.mkOption { type = lib.types.str; };
            prettyName = lib.mkOption { type = lib.types.str; };
          };
        };
        shellType = lib.types.submodule {
          options = {
            prettyName = lib.mkOption { type = lib.types.str; };
          };
        };
        sessionType = lib.types.submodule {
          options = {
            command = lib.mkOption { type = lib.types.str; };
            comment = lib.mkOption { type = lib.types.str; };
            desktopName = lib.mkOption { type = lib.types.str; };
            prettyName = lib.mkOption { type = lib.types.str; };
            shell = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Shell name exported as HDWLINUX_SHELL; null for monolithic sessions.";
            };
          };
        };
      in
      {
        options.hdwlinux.desktop.compositors = lib.mkOption {
          type = lib.types.attrsOf compositorType;
          default = { };
          description = "Wayland compositors contributing to the session matrix.";
        };
        options.hdwlinux.desktop.shells = lib.mkOption {
          type = lib.types.attrsOf shellType;
          default = { };
          description = "Desktop shells contributing to the session matrix.";
        };
        options.hdwlinux.desktop.sessions = lib.mkOption {
          type = lib.types.attrsOf sessionType;
          default = { };
          description = "Greetd sessions; the compositor×shell matrix is merged with explicit entries.";
        };
      };

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.desktop;
        # Cross-product of every registered compositor and shell; each session
        # name is <compositor>-<shell> and carries the shell name for the
        # session wrapper to export as HDWLINUX_SHELL.
        matrixSessions = lib.listToAttrs (
          lib.concatMap (
            compositorName:
            let
              compositor = cfg.compositors.${compositorName};
            in
            lib.mapAttrsToList (shellName: shell: {
              name = "${compositorName}-${shellName}";
              value = {
                inherit (compositor) command comment desktopName;
                prettyName = "${compositor.prettyName} + ${shell.prettyName}";
                shell = shellName;
              };
            }) cfg.shells
          ) (lib.attrNames cfg.compositors)
        );
        # The matrix is written into hdwlinux.desktop.sessions (merging with any
        # explicit monolithic entries), then rendered to greetd .desktop files.
        allSessions = matrixSessions // cfg.sessions;
        sessionFiles = lib.mapAttrsToList (
          name: session:
          let
            wrapper = pkgs.writeShellScript "hdwlinux-session-${name}" (
              lib.optionalString (session.shell != null) "export HDWLINUX_SHELL=${session.shell}\n"
              + "exec ${lib.getExe pkgs.uwsm} start -D ${session.desktopName} -e -F ${lib.escapeShellArg session.command}\n"
            );
          in
          pkgs.writeTextFile {
            name = "${name}-greetd-session";
            destination = "/share/greetd-sessions/${name}.desktop";
            text = ''
              [Desktop Entry]
              Name=${session.prettyName}
              Comment=${session.comment}
              DesktopNames=${session.desktopName}
              Exec=${wrapper}
              Type=Application
            '';
          }
        ) allSessions;
      in
      {
        # Feed the matrix into the sessions option so explicit monolithic
        # entries and generated cross-product sessions share one set.
        hdwlinux.desktop.sessions = matrixSessions;

        programs.uwsm.enable = true;
        environment.pathsToLink = [ "/share/greetd-sessions" ];
        environment.systemPackages = sessionFiles;
      };
  };
}
