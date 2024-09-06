{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.battery;
in
{
  options.hdwlinux.features.battery = {
    enable = lib.hdwlinux.mkBoolOpt true config.hdwlinux.features.tags;
    profile = lib.mkOption {
      type = lib.types.enum [
        "full_charge"
        "balanced"
      ];
      default = "max_lifespan";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.system76-battery-thresholds =
      lib.mkIf config.hardware.system76.power-daemon.enable
        {
          enable = true;
          description = "System76 Battery Thresholds";
          after = [ "default.target" ];
          wantedBy = [ "default.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.system76}/bin/system76-power charge-thresholds --profile ${cfg.profile}";
          };
        };
  };
}
