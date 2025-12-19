{
  config.substrate.modules.programs.gamemode = {
    tags = [ "gaming" ];
    nixos = {
      programs.gamemode = {
        enable = true;
      };
    };
  };
}

