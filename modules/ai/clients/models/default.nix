{
  config.substrate.modules.ai.clients.models = {
    tags = [ "ai:clients" ];

    homeManager =
      { config, lib, ... }:
      let
        aliasNames = [
          "analysis"
          "balanced"
          "code-review"
          "coding"
          "fast"
          "orchestration"
          "research"
          "writing"
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
            models = lib.mkOption {
              description = "Ordered list of provider/model entries. First is the primary model; the rest form the fallback chain.";
              type = lib.types.listOf (
                lib.types.submodule {
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
                }
              );
            };
          };
        };

        cfg = config.hdwlinux.ai.clients.models;
        configuredAliases = builtins.attrNames cfg.aliases;
        invalidAliases = lib.filter (key: !(builtins.elem key aliasNames)) configuredAliases;
      in
      {
        options.hdwlinux.ai.clients.models = {
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
            assertion = lib.all (alias: alias.models != [ ]) (lib.attrValues cfg.aliases);
            message = "Every model alias must define at least one entry in `models`.";
          }
        ];
      };
  };

  config.substrate.modules.ai.clients.models.craig-personal = {
    tags = [
      "users:craig:personal"
      "ai:clients"
    ];

    homeManager =
      { lib, ... }:
      let
        # Personal hosts route all aliases through the opencode-go provider
        go = model: {
          provider = "opencode-go";
          model = model;
        };
      in
      {
        hdwlinux.ai.clients.models.aliases = lib.mkDefault {
          analysis = {
            models = [
              (go "kimi-k3")
              (go "qwen3.8-max")
            ];
          };
          balanced = {
            models = [
              (go "deepseek-v4-pro")
              (go "glm-5.3")
            ];
          };
          code-review = {
            models = [
              (go "kimi-k2.7-code")
              (go "gpt-5.6-luna")
            ];
          };
          coding = {
            models = [
              (go "kimi-k2.7-code")
              (go "glm-5.3")
            ];
          };
          fast = {
            models = [
              (go "deepseek-v4-flash")
              (go "glm-5.3-flash")
            ];
          };
          orchestration = {
            models = [
              (go "qwen3.8-max")
              (go "qwen3.7-max")
            ];
          };
          research = {
            models = [
              (go "gpt-5.6-luna")
              (go "qwen3.7-plus")
            ];
          };
          writing = {
            models = [
              (go "gpt-5.6-luna")
              (go "qwen3.7-plus")
            ];
          };
        };
      };
  };

  config.substrate.modules.ai.clients.models.craig-work = {
    tags = [
      "users:craig:work"
      "ai:clients"
    ];

    homeManager =
      { lib, ... }:
      let
        # Work host routes aliases through the grove gateway (plugin pinned at v1.3.0).
        mk = provider: model: { inherit provider model; };
      in
      {
        hdwlinux.ai.clients.models.aliases = lib.mkDefault {
          analysis = {
            models = [
              (mk "grove-misc" "fw-glm-5.2")
              (mk "grove-openai" "gpt-5.6-terra")
              (mk "grove-anthropic" "claude-opus-4-7")
            ];
          };
          balanced = {
            models = [
              (mk "grove-anthropic" "claude-sonnet-5")
            ];
          };
          code-review = {
            models = [
              (mk "grove-misc" "fw-glm-5.2")
              (mk "grove-openai" "gpt-5.4")
              (mk "grove-misc" "fw-kimi-k2.7-code")
            ];
          };
          coding = {
            models = [
              (mk "grove-misc" "fw-deepseek-v4-pro")
              (mk "grove-misc" "fw-kimi-k2.7-code")
              (mk "grove-openai" "gpt-5.3-codex")
            ];
          };
          fast = {
            models = [
              (mk "grove-anthropic" "claude-haiku-4-5")
              (mk "grove-openai" "gpt-5.4-mini")
              (mk "grove-misc" "deepseek-v4-flash")
            ];
          };
          orchestration = {
            models = [
              (mk "grove-anthropic" "claude-opus-4-8")
              (mk "grove-openai" "gpt-5.6-sol")
            ];
          };
          research = {
            models = [
              (mk "grove-openai" "gpt-5.6-luna")
              (mk "grove-openai" "gpt-5.4")
              (mk "grove-misc" "fw-glm-5.2")
            ];
          };
          writing = {
            models = [
              (mk "grove-openai" "gpt-5.6-luna")
              (mk "grove-openai" "gpt-5.5")
            ];
          };
        };
      };
  };

}
