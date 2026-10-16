{
  config.substrate.modules.programs.lmstudio = {
    provides = [ "ai:llm" ];
    tags = [ "ai:llm" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.lmstudio
        ];
      };
  };
}
