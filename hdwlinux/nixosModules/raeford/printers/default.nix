{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.raeford.printers;
  ppdName = "Brother_HL-L2380DW.ppd";
  defaultName = "Brother_HL-L2380DW";
in
{
  options.hdwlinux.raeford.printers = {
    enable = config.lib.hdwlinux.mkEnableOption "raeford office printers" "raeford";
  };

  config = lib.mkIf cfg.enable {
    # Enable printing for raeford office
    hdwlinux.hardware.printers.enable = lib.mkDefault true;

    # Configure the specific Brother printer in the raeford office
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
}
