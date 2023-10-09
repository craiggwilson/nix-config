{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.suites.displayManagers.greetd;
in
{
  options.hdwlinux.suites.displayManagers.greetd = with types; {
    enable = mkBoolOpt false "Whether or not to enable greetd.";
  };

  config = mkIf cfg.enable {
    hdwlinux.packages.tuigreet.enable = true;

    services.greetd = {
      enable = true;
      settings = {
        vt = 7;
        default_session = {
          user = "greeter";
        };
      };
    };
  };
}
