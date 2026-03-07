{
  config.substrate.modules.ai.agent.models = {
    tags = [ "ai:agent" ];

    homeManager =
      { config, lib, ... }:
      let
        aliasNames = [
          "fast"
          "balanced"
          "coder"
          "analyst"
          "writer"
        ];

        modelType = lib.types.submodule (
          { name, ... }:
          {
            options = {
              name = lib.mkOption {
                description = "Model identifier for programmatic use.";
                type = lib.types.str;
                default = name;
              };

              displayName = lib.mkOption {
                description = "Human-readable model name for UI display.";
                type = lib.types.str;
                default = name;
              };

              limits = lib.mkOption {
                description = "Model token limits.";
                type = lib.types.submodule {
                  options = {
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
                };
                default = { };
              };
            };
          }
        );

        providerType = lib.types.submodule (
          { name, ... }:
          {
            options = {
              name = lib.mkOption {
                description = "Provider identifier for programmatic use.";
                type = lib.types.str;
                default = name;
              };

              displayName = lib.mkOption {
                description = "Human-readable provider name for UI display.";
                type = lib.types.str;
                default = name;
              };

              models = lib.mkOption {
                description = "Models available from this provider.";
                type = lib.types.attrsOf modelType;
                default = { };
              };
            };
          }
        );

        aliasType = lib.types.submodule {
          options = {
            provider = lib.mkOption {
              description = "Provider name (key) that provides this model.";
              type = lib.types.str;
            };

            model = lib.mkOption {
              description = "Model name (key) within the provider.";
              type = lib.types.str;
            };
          };
        };

        cfg = config.hdwlinux.ai.agent.models;
        configuredAliases = builtins.attrNames cfg.aliases;
        invalidAliases = lib.filter (key: !(builtins.elem key aliasNames)) configuredAliases;
        invalidRefs = lib.filter (
          aliasName:
          let
            alias = cfg.aliases.${aliasName};
            providerExists = cfg.providers ? ${alias.provider};
            modelExists = providerExists && (cfg.providers.${alias.provider}.models ? ${alias.model});
          in
          !modelExists
        ) configuredAliases;
      in
      {
        options.hdwlinux.ai.agent.models = {
          aliasNames = lib.mkOption {
            description = "Valid alias names for model aliases.";
            type = lib.types.listOf lib.types.str;
            readOnly = true;
            default = aliasNames;
          };

          providers = lib.mkOption {
            description = "AI model providers with their available models.";
            type = lib.types.attrsOf providerType;
            default = { };
          };

          aliases = lib.mkOption {
            description = "Model aliases that map to a specific provider and model.";
            type = lib.types.attrsOf aliasType;
            default = { };
          };
        };

        config.assertions = [
          {
            assertion = invalidAliases == [ ];
            message = "Invalid alias names: ${builtins.concatStringsSep ", " invalidAliases}. Valid names are: ${builtins.concatStringsSep ", " aliasNames}";
          }
          {
            assertion = invalidRefs == [ ];
            message = "Aliases reference non-existent provider/model combinations: ${builtins.concatStringsSep ", " invalidRefs}";
          }
        ];
      };
  };
}
