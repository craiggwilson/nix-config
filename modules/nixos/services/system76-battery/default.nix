{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.services.system76-battery;
in
{
  options.hdwlinux.services.system76-battery = {
    enable = lib.mkOption {
      description = "Wheter to enable system76 battery services.";
      type = lib.types.bool;
      default = config.hardware.system76.power-daemon.enable;
    };
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

  config = lib.mkIf cfg.enable {
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
