{
  config.substrate.modules.services.gamemode = {
    tags = [ "gaming" ];
    nixos = {
      programs.gamemode = {
        enable = true;
      };
    };
  };
}

