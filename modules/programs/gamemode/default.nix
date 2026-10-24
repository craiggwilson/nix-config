{
  config.substrate.modules.programs.gamemode = {
    tags = [ "profile:gaming" ];
    nixos = {
      programs.gamemode = {
        enable = true;
      };
    };
  };
}
