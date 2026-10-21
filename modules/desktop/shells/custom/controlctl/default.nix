{
  config.substrate.modules.desktop.shells.custom.controlctl = {
    tags = [ "desktop:shells:custom" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
            name = "controlctl";
            runtimeInputs = [
              pkgs.hyprlock
              pkgs.vicinae
            ];
            subcommands.show-menu = builtins.readFile ./control-menu.sh;
          })
        ];
      };
  };
}
