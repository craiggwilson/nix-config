{
  config.substrate.modules.desktop.shells.custom.wlsunset = {
    tags = [ "desktop:shells:custom" ];

    homeManager =
      { lib, ... }:
      {
        services.wlsunset = {
          enable = true;
          latitude = "32.7942";
          longitude = "-96.7655";
        };

        # Overrides home-manager's own string-valued definition.
        systemd.user.services.wlsunset.Unit.ConditionEnvironment = lib.mkForce "HDWLINUX_SHELL=custom";
      };
  };
}
