{
  config.substrate.modules.desktop.custom.networkmenu = {
    tags = [ "desktop:custom" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.writeShellScriptBin "networkmenu" (builtins.readFile ./networkmenu.sh))
        ];
      };
  };
}

