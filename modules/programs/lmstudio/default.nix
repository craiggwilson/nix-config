{
  config.substrate.modules.programs.lmstudio = {
    tags = [ "service:ai:llm" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.lmstudio
        ];
      };
  };
}
