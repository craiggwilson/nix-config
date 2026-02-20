{
  config.substrate.modules.ai.agent.models = {
    tags = [ "ai:agent" ];

    homeManager =
      { lib, ... }:
      let
        modelType = lib.types.submodule {
          options = {
            providers = lib.mkOption {
              description = "Program-specific model identifiers. Key is program name (e.g., opencode, augment).";
              type = lib.types.attrsOf lib.types.str;
              default = { };
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
          # Actual models
          "haiku4.5" = { };
          "opus4.5" = { };
          "opus4.6".fallback = "opus4.5";
          "sonnet4" = { };
          "sonnet4.5".fallback = "sonnet4";
          "gpt5" = { };
          "gpt5.1".fallback = "gpt5";
          "gpt5.2".fallback = "gpt5.1";

          # Aliases
          "small".fallback = "haiku4.5";
          "default".fallback = "sonnet4.5";
          "coding".fallback = "sonnet4.5";
          "reasoning".fallback = "opus4.5";
          "planning".fallback = "sonnet4.5";
          "explore".fallback = "haiku4.5";
        };
      };
  };
}
