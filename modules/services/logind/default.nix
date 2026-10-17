{
  config.substrate.modules.services.logind = {
    provides = [
      "services:logind"
      "core:session"
    ];

    nixos = {
      services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
    };
  };
}
