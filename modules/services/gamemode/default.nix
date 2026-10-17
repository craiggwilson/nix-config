{
  config.substrate.modules.services.gamemode = {
    provides = [
      "services:gamemode"
      "gaming"
    ];
    nixos = {
      programs.gamemode = {
        enable = true;
      };
    };
  };
}
