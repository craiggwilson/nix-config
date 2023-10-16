{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.packages.fingerprint;
in
{
  options.hdwlinux.packages.fingerprint = with types; {
    enable = mkBoolOpt false "Whether or not to configure fingerprint support.";
  };

  config = mkIf cfg.enable {
    services.fprintd.enable = true;
  };
}
