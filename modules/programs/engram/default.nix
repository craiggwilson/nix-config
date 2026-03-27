{
  config.substrate.modules.programs.engram = {
    tags = [ "ai:agent" ];

    homeManager =
      { pkgs, ... }:
      let
        toml = pkgs.formats.toml { };
      in
      {
        home.packages = [ pkgs.hdwlinux.engram-rs ];

        home.file.".config/engram/engram.toml".source = toml.generate "engram.toml" {
          indexed_paths = [
            {
              path = "~/Projects/kb/codebases";
              classification = "codebases";
              strength = 0.7;
            }
            {
              path = "~/Projects/kb/people";
              classification = "people";
              strength = 0.5;
            }
            {
              path = "~/Projects/kb/projects";
              classification = "projects";
              strength = 0.4;
            }
            {
              path = "~/Projects/kb/reference";
              classification = "reference";
              strength = 0.8;
            }
            {
              path = "~/Projects/kb/research";
              classification = "research";
              strength = 0.6;
            }
          ];
        };
      };
  };
}
