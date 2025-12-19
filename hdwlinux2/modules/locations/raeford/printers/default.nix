let
  ppdName = "Brother_HL-L2380DW.ppd";
  defaultName = "Brother_HL-L2380DW";
in
{
  config.substrate.modules.locations.raeford.printers = {
    tags = [ "raeford" "printing" ];

    nixos =
      { config, ... }:
      {
        hardware.printers = {
          ensureDefaultPrinter = defaultName;
          ensurePrinters = [
            {
              name = defaultName;
              description = "Brother HL-L2380DW";
              location = "Raeford";
              deviceUri = "ipp://printer.${config.hdwlinux.networking.domain}/ipp";
              model = ppdName;
            }
          ];
        };
      };
  };
}

