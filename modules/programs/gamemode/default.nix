{
  config.substrate.modules.programs.gamemode = {
    provides = [
      "programs:gamemode"
      "gaming"
    ];
    nixos = {
      programs.gamemode = {
        enable = true;
      };
    };
  };
}
