{
  config.substrate.modules.ai.agent.models = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        modelType = lib.types.submodule {
          options = {
            providers = lib.mkOption {
              description = "List of provider names that support this model (e.g., augment, github).";
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };

            limits = {
              context = lib.mkOption {
                description = "Maximum context window size in tokens.";
                type = lib.types.int;
                default = 200000;
              };

              output = lib.mkOption {
                description = "Maximum output tokens.";
                type = lib.types.int;
                default = 8000;
              };
            };

            fallback = lib.mkOption {
              description = "Model to fall back to if this model isn't available for a program. Also used for aliases.";
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
          };
        };
      in
      {
        options.hdwlinux.ai.agent.models = lib.mkOption {
          description = "Model definitions and aliases with provider mappings and fallback chains.";
          type = lib.types.attrsOf modelType;
          default = { };
        };

        config.hdwlinux.ai.agent.models = {
          "Claude Haiku 4.5" = {
            limits = {
              context = 200000;
              output = 8000;
            };
          };
          "Claude Opus 4.5" = {
            limits = {
              context = 200000;
              output = 32000;
            };
          };
          "Claude Opus 4.6" = {
            limits = {
              context = 200000;
              output = 32000;
            };
            fallback = "Claude Opus 4.5";
          };
          "Claude Sonnet 4" = {
            limits = {
              context = 200000;
              output = 16000;
            };
          };
          "Claude Sonnet 4.5" = {
            limits = {
              context = 200000;
              output = 16000;
            };
            fallback = "Claude Sonnet 4";
          };
          "Claude Sonnet 4.6" = {
            limits = {
              context = 200000;
              output = 16000;
            };
            fallback = "Claude Sonnet 4";
          };
          "GPT 5" = {
            limits = {
              context = 400000;
              output = 32000;
            };
          };
          "GPT 5.1" = {
            limits = {
              context = 400000;
              output = 32000;
            };
            fallback = "GPT 5";
          };
          "GPT 5.2" = {
            limits = {
              context = 400000;
              output = 32000;
            };
            fallback = "GPT 5.1";
          };

          # Aliases
          "small".fallback = "Claude Haiku 4.5";
          "default".fallback = "Claude Sonnet 4.5";
          "coding".fallback = "Claude Sonnet 4.5";
          "reasoning".fallback = "Claude Opus 4.5";
          "planning".fallback = "Claude Sonnet 4.5";
          "explore".fallback = "Claude Haiku 4.5";
        };
      };
  };
}
