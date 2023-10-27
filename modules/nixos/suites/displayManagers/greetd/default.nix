{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.suites.displayManagers.greetd;
in
{
  options.hdwlinux.suites.displayManagers.greetd = with types; {
    enable = mkBoolOpt false "Whether or not to enable greetd.";
    startCommand = mkOption { type = str; description = "The command to startup upon loginc."; };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      greetd.tuigreet
    ];

    security.pam.services.greetd.enableGnomeKeyring = true;

    services.greetd = {
      enable = true;
      settings = {
        vt = 7;
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --remember --remember-user-session --time --cmd ${cfg.startCommand}";
          user = "greeter";
        };
      };
    };
  };
}
