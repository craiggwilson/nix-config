{
  config.substrate.modules.services.gamemode = {
    provides = [ "services:gamemode" "gaming" ];
    tags = [ "gaming" ];
    nixos = {
      programs.gamemode = {
        enable = true;
      };
    };
  };
}
