{
  config.substrate.modules.services = {
    nixos = {
      systemd = {
        settings.Manager.DefaultTimeoutStopSec = "10s";
        user.settings.Manager.DefaultTimeoutStopSec = "10s";
      };
    };
  };
}
