{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.services.greetd;
  cmd = "uwsm start default";
in
{
  options.hdwlinux.services.greetd = {
    enable = lib.hdwlinux.mkEnableOption "greetd" true;
    user = lib.mkOption {
      description = "The user to login automatically.";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings =
        if cfg.user != null then
          rec {
            initial_session = {
              command = cmd;
              user = cfg.user;
            };
            default_session = initial_session;
          }
        else
          {
            default_session = {
              command = "${pkgs.greetd.tuigreet}/bin/tuigreet --remember --remember-session --time --cmd \"${cmd}\"";
              user = "greeter";
            };
          };
    };

    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
