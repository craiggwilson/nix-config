{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.services.battery;
in
{
  options.hdwlinux.services.battery = {
    enable = lib.hdwlinux.mkBoolOpt true config.hdwlinux.features.tags;
    profile = lib.mkOption {
      description = "The profile to use when setting the charge-thresholds on boot.";
      type = lib.types.enum [
        "full_charge"
        "balanced"
        "max_lifespan"
      ];
      default = "max_lifespan";
    };
  };

  config = lib.mkIf (cfg.enable && config.hardware.system76.power-daemon.enable) {
    systemd.services.system76-battery-thresholds = {
      enable = true;
      description = "Sets the System76 battery thresholds on boot";
      after = [ "default.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.system76-power}/bin/system76-power charge-thresholds --profile ${cfg.profile}";
      };
    };

    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="0", RUN+="${pkgs.system76-power}/bin/system76-power profile battery"
      SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="${pkgs.system76-power}/bin/system76-power profile performance"
    '';
  };
}
