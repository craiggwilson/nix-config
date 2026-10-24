{
  config.substrate.modules.services = {
    tags = [ "core:base" ];
    nixos = {
      systemd = {
        settings.Manager.DefaultTimeoutStopSec = "10s";
        user.settings.Manager.DefaultTimeoutStopSec = "10s";
      };
    };
  };
}
