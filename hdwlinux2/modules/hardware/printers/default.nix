let
  ppdName = "Brother_HL-L2380DW.ppd";
in
{
  config.substrate.modules.hardware.printers = {
    tags = [ "printing" ];

    nixos =
      { lib, pkgs, ... }:
      {
        services.printing = {
          enable = true;
          webInterface = false;
          browsing = false;

          drivers = lib.singleton (
            pkgs.linkFarm "drivers" [
              {
                name = "share/cups/model/${ppdName}";
                path = ./Brother_HL-L2380DW.ppd;
              }
            ]
          );
        };
      };
  };
}

