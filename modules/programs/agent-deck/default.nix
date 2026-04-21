{
  config.substrate.modules.programs.agent-deck = {
    tags = [ "ai:agent" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.agent-deck ];
      };
  };
}
