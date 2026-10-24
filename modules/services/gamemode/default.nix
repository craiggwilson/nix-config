{
  config.substrate.modules.services.gamemode = {
    tags = [ "profile:gaming" ];
    nixos = {
      programs.gamemode = {
        enable = true;
      };
    };
  };
}
