{
  config.substrate.modules.desktop.custom.audio = {
    tags = [ "desktop:custom" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.pavucontrol
          pkgs.wireplumber
        ];
      };
  };
}

