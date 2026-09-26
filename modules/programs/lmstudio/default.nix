{
  config.substrate.modules.programs.lmstudio = {
    tags = [ "ai:llm" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [
          pkgs.lmstudio
        ];
      };
  };
}
