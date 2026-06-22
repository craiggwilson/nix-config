{
  config.substrate.modules.programs.lmstudio = {
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
