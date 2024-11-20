{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.greetd;
in
{
  options.hdwlinux.services.greetd = {
    enable = lib.mkOption {
      description = "Whether to enable greetd, a minimal and flexible login manager daemon.";
      type = lib.types.bool;
      default = false;
    };
    user = lib.mkOption {
      description = "The user to login automatically.";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "dbus-run-session Hyprland";
          user = lib.mkIf (cfg.user != null) cfg.user;
        };
        default_session = initial_session;
      };
    };
  };
}
