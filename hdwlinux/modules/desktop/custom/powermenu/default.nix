{
  config.substrate.modules.desktop.custom.powermenu = {
    tags = [ "desktop:custom" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.writeShellScriptBin "powermenu" (builtins.readFile ./powermenu.sh))
        ];
      };
  };
}

