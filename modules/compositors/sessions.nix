{
  config.substrate.modules.compositors.sessions = {
    tags = [ "desktop" ];

    generic =
      { lib, ... }:
      {
        options.hdwlinux.compositors.sessions = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                command = lib.mkOption { type = lib.types.str; };
                comment = lib.mkOption { type = lib.types.str; };
                desktopName = lib.mkOption { type = lib.types.str; };
                prettyName = lib.mkOption { type = lib.types.str; };
              };
            }
          );
          default = { };
          description = "Wayland compositor sessions exposed through greetd.";
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
        sessions = lib.mapAttrsToList (
          name: compositor:
          pkgs.writeTextFile {
            name = "${name}-greetd-session";
            destination = "/share/greetd-sessions/${name}.desktop";
            text = ''
              [Desktop Entry]
              Name=${compositor.prettyName}
              Comment=${compositor.comment}
              DesktopNames=${compositor.desktopName}
              Exec=${lib.getExe pkgs.uwsm} start -D ${compositor.desktopName} -e -F ${compositor.command}
              Type=Application
            '';
          }
        ) config.hdwlinux.compositors.sessions;
      in
      {
        programs.uwsm.enable = true;
        environment.pathsToLink = [ "/share/greetd-sessions" ];
        environment.systemPackages = sessions;
      };
  };
}
