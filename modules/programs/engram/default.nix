{
  config.substrate.modules.programs.engram = {
    tags = [ "ai:agent" ];

    homeManager = {
      programs.engram = {
        enable = true;

        settings = {
          indexed_paths = [
            {
              path = "~/Projects/kb/codebases";
              class = "codebases";
              strength = 0.7;
            }
            {
              path = "~/Projects/kb/people";
              class = "people";
              strength = 0.5;
            }
            {
              path = "~/Projects/kb/projects";
              class = "projects";
              strength = 0.4;
            }
            {
              path = "~/Projects/kb/reference";
              class = "reference";
              strength = 0.8;
            }
            {
              path = "~/Projects/kb/research";
              class = "research";
              strength = 0.6;
            }
          ];
        };
      };
    };
  };
}
