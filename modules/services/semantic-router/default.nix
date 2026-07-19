{
  config.substrate.modules.services."semantic-router" = {
    tags = [ "ai:llm" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.services."semantic-router";
        llmModels = config.hdwlinux.ai.llm.models;
        modelNames = builtins.attrNames llmModels;
        semanticRouterPkg = builtins.getAttr "semantic-router" pkgs.hdwlinux;
        huggingfaceHub = pkgs.python312Packages.huggingface-hub;

        localLlamaBaseUrl = "http://127.0.0.1:9292/v1";

        defaultModelName =
          let
            balancedModels = lib.filter (
              name: builtins.elem "balanced" (llmModels.${name}.categories or [ ])
            ) modelNames;
          in
          if balancedModels != [ ] then builtins.head balancedModels else builtins.head modelNames;

        toModelCard = name: model: {
          inherit name;
          capabilities = [
            "chat"
          ]
          ++ lib.optionals (builtins.elem "vision" (model.categories or [ ])) [
            "vision"
            "multimodal"
          ];
          description = (model.settings.opencode or { }).name or name;
          modality = if builtins.elem "vision" (model.categories or [ ]) then "omni" else "ar";
        };

        toProviderModel = name: model: {
          inherit name;
          api_format = "openai";
          provider_model_id = name;
          backend_refs = [
            {
              name = "local-llama-cpp";
              provider = "openai";
              base_url = localLlamaBaseUrl;
              chat_path = "/chat/completions";
              protocol = "http";
              weight = 100;
            }
          ];
        };

        generatedConfig = {
          version = "v0.3";

          listeners = [
            {
              inherit (cfg) port;
              name = "http-${toString cfg.port}";
              address = cfg.host;
              timeout = "300s";
            }
          ];

          providers = {
            defaults = {
              default_model = defaultModelName;
            };
            models = lib.mapAttrsToList toProviderModel llmModels;
          };

          routing = {
            modelCards = lib.mapAttrsToList toModelCard llmModels;
            signals = {
              keywords = [
                {
                  name = "code_keywords";
                  operator = "OR";
                  keywords = [
                    "code"
                    "function"
                    "debug"
                    "algorithm"
                    "refactor"
                    "typescript"
                    "nix"
                  ];
                }
                {
                  name = "writing_keywords";
                  operator = "OR";
                  keywords = [
                    "write"
                    "rewrite"
                    "draft"
                    "summarize"
                    "edit"
                    "clarify"
                  ];
                }
              ];
              complexity = [
                {
                  name = "needs_reasoning";
                  threshold = 0.75;
                  description = "Escalate multi-step reasoning or synthesis-heavy prompts.";
                }
              ];
              modality = [
                {
                  name = "DIFFUSION";
                  description = "Image-generation requests.";
                }
                {
                  name = "BOTH";
                  description = "Requests that need both text and image generation.";
                }
              ];
              domains = [
                {
                  name = "computer science";
                  description = "Computer science and engineering prompts.";
                  mmlu_categories = [ "computer science" ];
                }
                {
                  name = "other";
                  description = "General fallback traffic.";
                  mmlu_categories = [ "other" ];
                }
              ];
            };

            decisions = [
              {
                name = "vision-route";
                priority = 100;
                rules = {
                  operator = "OR";
                  conditions = [
                    {
                      type = "modality";
                      name = "DIFFUSION";
                    }
                    {
                      type = "modality";
                      name = "BOTH";
                    }
                  ];
                };
                modelRefs = [
                  {
                    model = lib.findFirst (
                      name: builtins.elem "vision" (llmModels.${name}.categories or [ ])
                    ) defaultModelName modelNames;
                    use_reasoning = false;
                  }
                ];
              }
              {
                name = "coder-route";
                priority = 90;
                rules = {
                  operator = "OR";
                  conditions = [
                    {
                      type = "keyword";
                      name = "code_keywords";
                    }
                    {
                      type = "domain";
                      name = "computer science";
                    }
                  ];
                };
                modelRefs = [
                  {
                    model = lib.findFirst (
                      name: builtins.elem "coder" (llmModels.${name}.categories or [ ])
                    ) defaultModelName modelNames;
                    use_reasoning = false;
                  }
                ];
              }
              {
                name = "analyst-route";
                priority = 80;
                rules = {
                  operator = "OR";
                  conditions = [
                    {
                      type = "complexity";
                      name = "needs_reasoning";
                    }
                    {
                      type = "keyword";
                      name = "writing_keywords";
                    }
                  ];
                };
                modelRefs = [
                  {
                    model = lib.findFirst (
                      name: builtins.elem "analyst" (llmModels.${name}.categories or [ ])
                    ) defaultModelName modelNames;
                    use_reasoning = true;
                  }
                ];
              }
              {
                name = "default-route";
                priority = 10;
                rules = {
                  operator = "AND";
                  conditions = [
                    {
                      type = "domain";
                      name = "other";
                    }
                  ];
                };
                modelRefs = [
                  {
                    model = defaultModelName;
                    use_reasoning = false;
                  }
                ];
              }
            ];
          };

          global = {
            router = {
              config_source = "file";
              auto_model_name = "router";
              auto_model_names = [
                "semantic-router/router"
                "router"
                "auto"
                "MoM"
              ];
              include_config_models_in_list = true;
              clear_route_cache = true;
              skip_processing = {
                enabled = false;
              };
              model_selection = {
                enabled = true;
                method = "priority";
              };
            };
            services = {
              startup_status = {
                store_backend = "file";
              };
            };
          };
        };

        routerConfig = pkgs.writeText "semantic-router-config.yaml" (
          lib.generators.toYAML { } generatedConfig
        );
      in
      {
        options.hdwlinux.services."semantic-router" = {
          host = lib.mkOption {
            description = "Host for the semantic-router apiserver and extproc endpoints.";
            type = lib.types.str;
            default = "127.0.0.1";
          };

          port = lib.mkOption {
            description = "OpenAI-compatible router port.";
            type = lib.types.int;
            default = 8899;
          };
        };

        config = {
          xdg.configFile."semantic-router/config.yaml".source = routerConfig;

          systemd.user.services."semantic-router" = {
            Unit = {
              Description = "vLLM Semantic Router";
              After = [ "network.target" ];
            };
            Install = {
              WantedBy = [ "default.target" ];
            };
            Service = {
              Environment = [
                "PATH=${
                  lib.makeBinPath [ huggingfaceHub ]
                }:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin"
              ];
              Type = "simple";
              ExecStart = "${lib.getExe semanticRouterPkg} --config ${config.xdg.configHome}/semantic-router/config.yaml";
              Restart = "on-failure";
              RestartSec = 10;
              KillSignal = "SIGINT";
            };
          };
        };
      };
  };
}
