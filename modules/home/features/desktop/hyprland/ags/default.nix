{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

let
  cfg = config.hdwlinux.features.desktop.hyprland.ags;
in
{
  options.hdwlinux.features.desktop.hyprland.ags = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "ags-debug" ''
        ags --config ${flake}/modules/home/feature/desktop/hyprland/ags/src/config-debug.js
      '')
    ];

    programs.ags = {
      enable = true;
    };

    #xdg.configFile."ags".source = ./src;
    xdg.configFile."ags/config.js".text = ''
      const main = '/tmp/ags/main.js';

      try {
          await Utils.execAsync([
              '${pkgs.bun}/bin/bun', 'build', `${./src/main.ts}`,
              '--outfile', main,
              '--external', 'resource://*',
              '--external', 'gi://*',
              '--external', 'file://*',
          ]);
          await import(`file://$${main}`);
      } catch (error) {
          console.error(error);
          App.quit();
      }

      export {}
    '';

  };
}
