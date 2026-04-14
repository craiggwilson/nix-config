{
  config.substrate.modules.programs.mestra = {
    tags = [ "ai:agent" ];

    homeManager = {
      programs.mestra = {
        enable = true;
        enableCuda = true;
        localEmbeddingModel = {
          name = "bge-m3";
          url = "https://huggingface.co/Vsevolod/bge-m3-safetensors/resolve/main";
          files = {
            model = {
              name = "model.safetensors";
              hash = "sha256-vwZTgSt0D8LViAzXe+sb4dLKCAy5XeLh0UUs/ioXpco=";
            };
            tokenizer = {
              name = "tokenizer.json";
              hash = "sha256-IRBrbX2rKVLB1Jb7IdXcnbdcKO02GgX1Agu7ongQ3Qg=";
            };
            config = {
              name = "config.json";
              hash = "sha256-JhWeetBlBzRIRgEX6yS3pFcvb0546t/2XcChHAUkSfo=";
            };
          };
        };

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
