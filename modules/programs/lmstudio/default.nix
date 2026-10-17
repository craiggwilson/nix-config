{
  config.substrate.modules.programs.lmstudio = {
    provides = [
      "programs:lmstudio"
      "ai:llm"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.lmstudio
        ];
      };
  };
}
