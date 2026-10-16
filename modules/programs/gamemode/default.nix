{
  config.substrate.modules.programs.gamemode = {
    provides = [ "gaming" ];
    tags = [ "gaming" ];
    nixos = {
      programs.gamemode = {
        enable = true;
      };
    };
  };
}
