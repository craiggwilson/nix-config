{
  config.substrate.modules.services.gamemode = {
    provides = [ "gaming" ];
    tags = [ "gaming" ];
    nixos = {
      programs.gamemode = {
        enable = true;
      };
    };
  };
}
