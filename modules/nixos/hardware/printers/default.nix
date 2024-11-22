{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.hardware.printers;
  ppdName = "Brother_HL-L2380DW.ppd";
  defaultName = "Brother_HL-L2380DW";
in
{
  options.hdwlinux.hardware.printers = {
    enable = lib.hdwlinux.mkEnableTagsOpt "printing" [ "printing" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
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

    hardware.printers = lib.mkIf (builtins.elem "raeford" config.hdwlinux.features.tags) {
      ensureDefaultPrinter = defaultName;
      ensurePrinters = [
        {
          name = defaultName;
          description = "Brother HL-L2380DW";
          location = "Raeford";
          deviceUri = "ipp://printer.raeford.wilsonfamilyhq.com/ipp";
          model = ppdName;
        }
      ];
    };
  };
}
