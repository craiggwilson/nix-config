{
  config.substrate.modules.services.logind = {
    tags = [ "core:base" ];
    nixos = {
      services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
    };
  };
}
