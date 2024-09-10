{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.printing;
in
{
  options.hdwlinux.features.printing = {
    enable = lib.hdwlinux.mkEnableOpt [ "printing" ] config.hdwlinux.features.tags;
    raeford = lib.hdwlinux.mkBoolOpt false "Wheter or not to enable Raeford printers.";
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
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
    };

    hardware.printers =
      let
        defaultName = "Brother_HL-L2380DW";
      in
      {
        ensureDefaultPrinter = defaultName;
        ensurePrinters = lib.optionals cfg.raeford [
          {
            name = defaultName;
            description = "Brother HL-L2380DW";
            location = "Raeford";
            deviceUri = "ipp://printer.raeford.wilsonfamilyhq.com/ipp";
            model = "everywhere";
          }
        ];
      };
  };
}
