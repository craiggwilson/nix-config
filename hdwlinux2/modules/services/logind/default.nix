{
  config.substrate.modules.services.logind = {
    nixos = {
      services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
    };
  };
}

