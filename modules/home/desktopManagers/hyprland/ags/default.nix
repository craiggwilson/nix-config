{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.ags;
in
{
  options.hdwlinux.desktopManagers.hyprland.ags = {
    enable = lib.hdwlinux.mkEnableOption "ags" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (inputs.ags.lib.bundle {
        inherit pkgs;
        src = ./src;
        name = "hdwshell"; # name of executable
        entry = "app.ts";

        # additional libraries and executables to add to gjs' runtime
        extraPackages = builtins.attrValues (
          builtins.removeAttrs inputs.astal.packages.${pkgs.system} [
            "cava"
            "docs"
          ]
        );
      })
    ];
  };
}
