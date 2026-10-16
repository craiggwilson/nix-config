{
  config.substrate.modules.programs.gamemode = {
    provides = [ "programs:gamemode" "gaming" ];
    tags = [ "gaming" ];
    nixos = {
      programs.gamemode = {
        enable = true;
      };
    };
  };
}
