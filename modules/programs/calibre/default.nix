{
  config.substrate.modules.programs.calibre = {
    tags = [ "gui" "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        programs.calibre = {
          enable = true;
          plugins = [
            "${pkgs.fetchzip {
              url = "https://github.com/JimmXinu/FanFicFare/releases/download/v4.56.0/FanFicFarePlugin-v4.56.0.zip";
              hash = "sha256-mslEit5mqKi7SxSPV5QDnjp+i5vN4fvynxoCV6ypYwM=";
              stripRoot=false;
            }}"
          ];
        };
      };
  };
}

