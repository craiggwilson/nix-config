{
  config.substrate.modules.services.system76-battery = {
    tags = [ "hardware:system76-serval-ws" ];
    nixos = { pkgs, ... }: {
      systemd.services.system76-battery-thresholds = {
        enable = true;
        description = "Sets the System76 battery thresholds on boot";
        after = [ "default.target" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.system76-power}/bin/system76-power charge-thresholds --profile max_lifespan";
        };
      };

      services.udev.extraRules = ''
        SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="0", RUN+="${pkgs.system76-power}/bin/system76-power profile battery"
        SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="${pkgs.system76-power}/bin/system76-power profile performance"
      '';
    };
  };
}

