{
  config.substrate.modules.desktop.custom.appctl = {
    tags = [ "desktop:custom" ];

    homeManager =
      {
        lib,
        config,
        pkgs,
        ...
      }:
      let
        getAppExe =
          app: argGroup:
          let
            path = if app.program != null then lib.getExe' app.package app.program else lib.getExe app.package;
            args =
              if argGroup == "default" && !builtins.hasAttr "default" app.argGroups then
                ""
              else
                " " + (lib.strings.concatStringsSep " " app.argGroups.${argGroup});
          in
          "${path}${args}";
        execKnown = app: argGroup: "uwsm app -- ${getAppExe app argGroup} \"$@\"";
        known = lib.mapAttrs (
          name: app:
          let
            argGroups =
              if builtins.hasAttr "default" app.argGroups then
                app.argGroups
              else
                app.argGroups // { "default" = null; };
          in
          lib.mapAttrs' (
            argGroup: _:
            lib.nameValuePair (if argGroup == "default" then "*" else argGroup) (execKnown app argGroup)
          ) argGroups
        ) config.hdwlinux.apps;
      in
      {
        home.packages = [
          (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
            name = "appctl";
            runtimeInputs = [
              pkgs.procps
              pkgs.uwsm
              pkgs.vicinae
            ];
            subcommands = {
              exec = "uwsm app -- \"$@\"";
              exec-known = known;
              show-menu = "vicinae vicinae://toggle";
              show-windows = "vicinae 'vicinae://launch/windows?toggle=true'";
            };
          })
        ];
      };
  };
}
