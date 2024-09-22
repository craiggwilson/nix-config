{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.printing;
  ppdName = "Brother_HL-L2380DW.ppd";
  defaultName = "Brother_HL-L2380DW";
in
{
  options.hdwlinux.features.printing = {
    enable = lib.hdwlinux.mkEnableOpt [ "printing" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services.printing = {
      enable = true;
      webInterface = false;
      browsing = true;
      browsedConf = ''
        BrowseDNSSDSubTypes _cups,_print
        BrowseLocalProtocols all
        BrowseRemoteProtocols all
        CreateIPPPrinterQueues All

        BrowseProtocols all
      '';

      drivers = lib.singleton (
        pkgs.linkFarm "drivers" [
          {
            name = "share/cups/model/${ppdName}";
            path = ./Brother_HL-L2380DW.ppd;
          }
        ]
      );
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
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
