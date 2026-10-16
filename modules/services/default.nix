{
  # Sane shutdown deadlines for the system manager and every user
  # manager, a small and scoped core concern.
  config.substrate.modules.services = {
    provides = [ "services" "core:systemd" ];

    nixos = {
      systemd = {
        settings.Manager.DefaultTimeoutStopSec = "10s";
        user.settings.Manager.DefaultTimeoutStopSec = "10s";
      };
    };
  };
}
