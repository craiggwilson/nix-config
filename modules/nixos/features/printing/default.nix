{
  options,
  config,
  pkgs,
  lib,
  host ? "",
  format ? "",
  inputs ? { },
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.printing;
in
{
  options.hdwlinux.features.printing = with types; {
    enable = mkEnableOpt [ "printing" ] config.hdwlinux.features.tags;
    raeford = mkBoolOpt false "Wheter or not to enable Raeford printers.";
  };

  config = mkIf cfg.enable {
    services.printing = {
      enable = true;
      webInterface = false;
      clientConf = ''
        AllowExpiredCerts Yes
      '';
    };

    hardware.printers.ensurePrinters = lib.optionals cfg.raeford [
      {
        name = "Brother_HL-L2380DW";
        location = "Raeford";
        deviceUri = "https://printer.raeford.wilsonfamilyhq.com";
        model = "drv:///sample.drv/generic.ppd";
      }
    ];
  };
}
