{ lib, ... }:
let
  # app-X uwsm launcher scripts. Each scope generates from the app providers
  # configured within it; content is identical once all providers migrate.
  mkAppScripts =
    config: pkgs:
    let
      apps = lib.filterAttrs (_: app: app != null) config.hdwlinux.app;
    in
    lib.mapAttrsToList (
      name: app:
      pkgs.writeShellScriptBin "app-${name}" ''
        exec uwsm app -- ${lib.getExe app.package}${lib.optionalString (app.args != [ ]) " ${lib.concatStringsSep " " app.args}"} "$@"
      ''
    ) apps;
in
{
  config.substrate.modules.apps = {
    generic = {
      options.hdwlinux.app =
        let
          appType = lib.types.nullOr (lib.types.submodule {
            options = {
              package = lib.mkOption {
                description = "The app's package.";
                type = lib.types.package;
              };
              desktopName = lib.mkOption {
                description = "The .desktop file name for MIME associations.";
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              args = lib.mkOption {
                description = "Default arguments passed to the program on launch.";
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
            };
          });
        in
        {
          terminal = lib.mkOption {
            description = "The terminal emulator.";
            type = appType;
            default = null;
          };
          webBrowser = lib.mkOption {
            description = "The default web browser.";
            type = appType;
            default = null;
          };
          fileManager = lib.mkOption {
            description = "The file manager.";
            type = appType;
            default = null;
          };
          passwordManager = lib.mkOption {
            description = "The password manager.";
            type = appType;
            default = null;
          };
          passwordManager-toggle = lib.mkOption {
            description = "Toggle the password manager.";
            type = appType;
            default = null;
          };
          passwordManager-lock = lib.mkOption {
            description = "Lock the password manager.";
            type = appType;
            default = null;
          };
          archiver = lib.mkOption {
            description = "The archive manager.";
            type = appType;
            default = null;
          };
          documentViewer = lib.mkOption {
            description = "The document viewer.";
            type = appType;
            default = null;
          };
          imageViewer = lib.mkOption {
            description = "The image viewer.";
            type = appType;
            default = null;
          };
        };
    };

    perUser =
      { config, pkgs, ... }:
      {
        packages = mkAppScripts config pkgs;
      };

    homeManager =
      { config, pkgs, ... }:
      {
        home.packages = mkAppScripts config pkgs;
      };
  };
}
