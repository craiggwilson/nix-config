{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.packages.printing.brother.laser;
in
{
  options.hdwlinux.packages.printing.brother.laser = with types; {
    enable = mkBoolOpt false "Whether or not to configure brother laser support.";
  };

  config = mkIf cfg.enable {
    services.printing.drivers = with pkgs; [
      brlaser
    ];
  };
}
