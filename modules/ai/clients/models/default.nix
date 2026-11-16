{
  config.substrate.modules.ai.clients.models = {
    tags = [ "profile:ai" ];

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

        providerType = lib.types.submodule (
          { name, ... }:
          {
            options = {
              auth = lib.mkOption {
                description = "Static credential sent as a request header. Null when the client authenticates some other way (OAuth, built-in key handling).";
                type = lib.types.nullOr (
                  lib.types.submodule {
                    options = {
                      header = lib.mkOption {
                        description = "Header that carries the credential.";
                        type = lib.types.str;
                        default = "Authorization";
                      };

                      prefix = lib.mkOption {
                        description = "Text placed before the secret in the header value.";
                        type = lib.types.str;
                        default = "Bearer ";
                      };

                      secret = lib.mkOption {
                        description = "Name of the environment variable holding the credential.";
                        type = lib.types.str;
                      };
                    };
                  }
                );
                default = null;
              };

              baseURL = lib.mkOption {
                description = "API base URL. Null for providers that clients already ship.";
                type = lib.types.nullOr lib.types.str;
                default = null;
              };

              builtin = lib.mkOption {
                description = "Clients already ship their own definition of this provider, so only its id matters.";
                type = lib.types.bool;
                default = false;
              };

              displayName = lib.mkOption {
                description = "Human-readable provider name for UI display.";
                type = lib.types.str;
                default = name;
              };

              formats = lib.mkOption {
                description = "API formats the endpoint accepts. Clients choose which one to speak.";
                type = lib.types.listOf (
                  lib.types.enum [
                    "anthropic"
                    "completions"
                    "gemini"
                    "responses"
                  ]
                );
                default = [ "completions" ];
              };

              settings = lib.mkOption {
                description = "Client-specific overrides, keyed by client (e.g. opencode).";
                type = lib.types.attrsOf lib.types.anything;
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
                      description = "Provider id, a key of `providers`.";
                      type = lib.types.str;
                    };

                    model = lib.mkOption {
                      description = "Model id as discovered from the provider.";
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
        referencedProviders = lib.concatMap (alias: map (entry: entry.provider) alias.models) (
          lib.attrValues cfg.aliases
        );
        missingProviders = lib.unique (lib.filter (id: !(cfg.providers ? ${id})) referencedProviders);
      in
      {
        options.hdwlinux.ai.clients.models = {
          aliasNames = lib.mkOption {
            description = "Valid alias names for model aliases.";
            type = lib.types.listOf lib.types.str;
            readOnly = true;
            default = aliasNames;
          };

          aliases = lib.mkOption {
            description = "Model aliases that map to a specific provider and model.";
            type = lib.types.attrsOf aliasType;
            default = { };
          };

          providers = lib.mkOption {
            description = "Connection details of AI model providers. Models are discovered, never listed here.";
            type = lib.types.attrsOf providerType;
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
          {
            assertion = missingProviders == [ ];
            message = "Aliases refer to unknown providers: ${builtins.concatStringsSep ", " missingProviders}.";
          }
        ];
      };
  };

  config.substrate.modules.ai.clients.models.personal = {
    tags = [
      "profile:personal"
      "profile:ai"
    ];

    homeManager =
      { lib, ... }:
      let
        # Personal hosts route aliases through agentgateway's tier aliases
        # (llm.virtualModels in the gateway config); the failover chain lives
        # there, so each alias is a single entry that can be retargeted at the
        # gateway without touching OpenCode.
        tier = name: {
          provider = "agentgateway";
          model = name;
        };
      in
      {
        hdwlinux.ai.clients.models.aliases = lib.mkDefault {
          analysis.models = [ (tier "analysis") ];
          balanced.models = [ (tier "balanced") ];
          code-review.models = [ (tier "code-review") ];
          coding.models = [ (tier "coding") ];
          fast.models = [ (tier "fast") ];
          orchestration.models = [ (tier "orchestration") ];
          research.models = [ (tier "research") ];
          writing.models = [ (tier "writing") ];
        };
      };
  };

  config.substrate.modules.ai.clients.models.craig-work = {
    tags = [
      "user:craig"
      "profile:work"
      "profile:ai"
    ];

    homeManager =
      { lib, ... }:
      let
        # Work host routes aliases through Grove (the AI Gateway upstream;
        # providers auto-provisioned by the grove-gateway OpenCode plugin) and
        # directly to fireworks.ai for open-source models. ai-gateway-* model
        # keys come from the plugin's catalog (models.jsonc upstream). No
        # deepseek: it is being retired for us. Fireworks "latest" routers
        # track the current generation (GLM 5.3, Kimi K3.1 Pro).
        mk = provider: model: { inherit provider model; };
        fw = model: mk "fireworks-ai" "accounts/fireworks/models/${model}";
        router = model: mk "fireworks-ai" "accounts/fireworks/routers/${model}";
      in
      {
        hdwlinux.ai.clients.models.aliases = lib.mkDefault {
          analysis = {
            models = [
              (fw "kimi-k3p1-pro")
              (mk "ai-gateway-misc" "fw-kimi-k3")
              (mk "ai-gateway-anthropic" "claude-opus-5-5")
              (mk "ai-gateway-openai" "gpt-6.1-sol")
            ];
          };
          balanced = {
            models = [
              (router "glm-latest")
              (mk "ai-gateway-anthropic" "claude-sonnet-5-5")
            ];
          };
          code-review = {
            models = [
              (router "glm-latest")
              (mk "ai-gateway-misc" "fw-glm-5.3")
              (mk "ai-gateway-openai" "gpt-6.1-sol")
              (fw "kimi-k3p1-pro")
            ];
          };
          coding = {
            models = [
              (fw "kimi-k3p1-pro")
              (mk "ai-gateway-misc" "fw-kimi-k3")
              (mk "ai-gateway-openai" "gpt-6.1-sol")
              (mk "ai-gateway-openai" "gpt-5.3-codex")
            ];
          };
          fast = {
            models = [
              (router "glm-flash-latest")
              (mk "ai-gateway-openai" "gpt-6-luna")
              (mk "ai-gateway-openai" "gpt-5.4-mini")
              (mk "ai-gateway-anthropic" "claude-haiku-4-5")
            ];
          };
          orchestration = {
            models = [
              (mk "ai-gateway-anthropic" "claude-opus-5-5")
              (mk "ai-gateway-openai" "gpt-6.1-sol")
              (fw "qwen3p8-max")
            ];
          };
          research = {
            models = [
              (mk "ai-gateway-openai" "gpt-6-luna")
              (mk "ai-gateway-openai" "gpt-6.1-sol")
              (mk "ai-gateway-misc" "fw-glm-5.3")
              (router "glm-latest")
            ];
          };
          writing = {
            models = [
              (mk "ai-gateway-openai" "gpt-6-luna")
              (mk "ai-gateway-openai" "gpt-5.5")
              (fw "kimi-k3p1-pro")
            ];
          };
        };
      };
  };

}
