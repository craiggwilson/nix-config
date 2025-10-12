{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.hardware.printers;
  ppdName = "Brother_HL-L2380DW.ppd";
in
{
  options.hdwlinux.hardware.printers = {
    enable = config.lib.hdwlinux.mkEnableOption "printing" "printing";
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

  };
}
