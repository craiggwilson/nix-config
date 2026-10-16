{
  config.substrate.modules.services.logind = {
    provides = [ "core:session" ];

    nixos = {
      services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
    };
  };
}
