{
  config.substrate.modules.programs.opencode = {
    tags = [
      "ai:clients"
    ];

    perUser =
      {
        config
        , lib
        , pkgs
        , ...
      }:
      let
        # Resolve an alias to its ordered "provider/model" fallback chain.
        # First entry is the primary model.
        resolveAliases =
          aliasName:
          let
            alias = config.hdwlinux.ai.clients.models.aliases.${aliasName};
          in
          map (m: "${m.provider}/${m.model}") alias.models;

        # Primary "provider/model" for single-model consumers (agent definitions, small_model)
        resolveAlias = aliasName: lib.head (resolveAliases aliasName);

        # Transform tools attrset for OpenCode config (boolean values)
        # "allow" -> true, "ask"/"deny" -> false
        transformTools = tools: lib.mapAttrs (_: perm: perm == "allow") tools;

        agentConfig = lib.mapAttrs (
          name: agent:
          {
            inherit (agent) color description mode;
            model = resolveAlias agent.model;
            prompt = "{file:${config.homeDirectory}/.config/opencode/prompts/agents/${name}.md}";
            inherit (agent) temperature;
          }
          // lib.optionalAttrs (agent.tools != { }) { tools = transformTools agent.tools; }
        ) config.hdwlinux.ai.clients.agents;

        commandConfig = lib.mapAttrs (name: command: {
          inherit (command) description;
          template = "{file:${config.homeDirectory}/.config/opencode/prompts/commands/${name}.md}";
        }) config.hdwlinux.ai.clients.commands;

        ruleInstructions = lib.mapAttrsToList (
          name: _rule: "${config.homeDirectory}/.config/opencode/prompts/rules/${name}.md"
        ) config.hdwlinux.ai.clients.rules;

        # Provider metadata: OpenCode-specific configuration for each provider
        providerMeta = {
          "llama.cpp" = {
            npm = "@ai-sdk/openai-compatible";
            options = lib.optionalAttrs (config.hdwlinux ? services.llama-cpp) {
              baseURL = "http://${config.hdwlinux.services.llama-cpp.host}:${toString config.hdwlinux.services.llama-cpp.port}/v1";
            };
            # llama.cpp models may have additional opencode-specific settings
            transformModel =
              slug: model:
              let
                llmModel = config.hdwlinux.ai.llm.models.${slug} or { };
                oc = llmModel.settings.opencode or { };
              in
              {
                id = slug;
                name = model.displayName;
                limit = {
                  context = model.limits.context;
                  output = model.limits.output;
                };
              }
              // lib.optionalAttrs (oc ? reasoning) { inherit (oc) reasoning; }
              // lib.optionalAttrs (oc ? tool_call) { inherit (oc) tool_call; };
          };
          "fireworks-ai" = {
            npm = "@ai-sdk/openai-compatible";
            env = [ "FIREWORKS_API_KEY" ];
            options = {
              baseURL = "https://api.fireworks.ai/inference/v1";
            };
          };
        };

        # Build providers config from hdwlinux.ai.clients.models.providers
        # Only include providers that have metadata defined
        providers = lib.mapAttrs (
          providerKey: provider:
          let
            meta = providerMeta.${providerKey} or { };
            transformModel =
              meta.transformModel or (slug: model: {
                id = slug;
                name = model.displayName;
                limit = {
                  context = model.limits.context;
                  output = model.limits.output;
                };
              });
          in
          {
            npm = meta.npm or null;
            name = provider.displayName;
            models = lib.mapAttrs (slug: model: transformModel slug model) provider.models;
          }
          // lib.optionalAttrs (meta ? options && meta.options != { }) { inherit (meta) options; }
          // lib.optionalAttrs (meta ? env && meta.env != [ ]) { inherit (meta) env; }
        ) (lib.filterAttrs (k: _: providerMeta ? ${k}) config.hdwlinux.ai.clients.models.providers);

        # MCP servers in opencode's shape (was home-manager's enableMcpIntegration
        # via programs.mcp; now derived from the same source options directly).
        mcpServers = lib.mapAttrs (
          _: server:
          if server ? stdio then
            {
              type = "local";
              command = [ server.stdio.command ] ++ server.stdio.args;
            }
          else if server ? http then
            {
              type = "remote";
              url = server.http.url;
            }
            // lib.optionalAttrs (server.http.headers != { }) {
              headers = server.http.headers;
            }
          else
            throw "Unknown MCP server type"
        ) config.hdwlinux.ai.clients.mcpServers;

        # Opencode theme derived from the active hdwlinux theme colors
        opencodeTheme = import ./_theme.nix config.hdwlinux.theme.colors;

        jsonFormat = pkgs.formats.json { };
        json = name: v: jsonFormat.generate name v;

        settings = {
          "$schema" = "https://opencode.ai/config.json";
          provider = providers;
          agent = agentConfig;
          command = commandConfig;
          instructions = ruleInstructions;
          permission = config.hdwlinux.ai.clients.tools;
          small_model = resolveAlias "fast";
          lsp = true;
          mcp = mcpServers;
          plugin = config.hdwlinux.programs.opencode.plugins;
        };
      in
      {
        options.hdwlinux.programs.opencode.plugins = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Plugin entries merged into opencode.json's plugin list.";
        };

        config = {
          packages = [ pkgs.opencode-desktop ];

          files = {
            ".config/opencode/opencode.json".source = json "opencode.json" settings;

            ".config/opencode/tui.json".source = json "tui.json" {
              "$schema" = "https://opencode.ai/tui.json";
              theme = "hdwlinux";
              keybinds = {
                app_exit = "ctrl+q";
              };
            };

            ".config/opencode/themes/hdwlinux.json".source = json "hdwlinux-theme.json" (
              { "$schema" = "https://opencode.ai/theme.json"; } // opencodeTheme
            );
          }
          // lib.mapAttrs' (
            name: command: lib.nameValuePair ".config/opencode/prompts/commands/${name}.md" { source = command.prompt; }
          ) config.hdwlinux.ai.clients.commands
          // lib.mapAttrs' (
            name: rule: lib.nameValuePair ".config/opencode/prompts/rules/${name}.md" { source = rule.prompt; }
          ) config.hdwlinux.ai.clients.rules
          // lib.mapAttrs' (
            name: agent: lib.nameValuePair ".config/opencode/prompts/agents/${name}.md" { source = agent.prompt; }
          ) config.hdwlinux.ai.clients.agents
          // lib.mapAttrs' (
            name: skill: lib.nameValuePair ".config/opencode/skills/${name}" { source = skill; }
          ) config.hdwlinux.ai.clients.skills;
        };
      };
  };

  config.substrate.modules.programs.opencode.grove-gateway = {
    tags = [
      "ai:clients"
      "users:craig:work"
    ];

    perUser =
      { pkgs, ... }:
      let
        # grove-gateway-opencode-plugin directory in the nix store
        grovePluginDir = "${
          pkgs.callPackage ./plugins/_grove_gateway.nix { }
        }/lib/grove-gateway-opencode-plugin";
      in
      {
        hdwlinux.programs.opencode.plugins = [
          "file://${grovePluginDir}"
        ];

        # Allow non-Grove providers (e.g. fireworks) to coexist with Grove providers.
        # Without this, the grove gateway plugin defaults to filtering out all non-Grove
        # providers except github-copilot.
        files.".config/opencode/grove.jsonc".text = builtins.toJSON {
          allowProviders = "*";
        };
      };
  };

  config.substrate.modules.programs.opencode.opencode-mem = {
    tags = [
      "ai:clients"
    ];

    perUser =
      { config, lib, ... }:
      let
        # Use the primary model from the analysis alias so the memory plugin follows
        # the same host-specific provider routing as the rest of OpenCode.
        resolvePrimaryAlias = aliasName: lib.head config.hdwlinux.ai.clients.models.aliases.${aliasName}.models;

        analysisModel = resolvePrimaryAlias "analysis";

        opencodeMemConfig = {
          storagePath = "~/.opencode-mem/data";

          opencodeProvider = analysisModel.provider;
          opencodeModel = analysisModel.model;

          embeddingModel = "Xenova/nomic-embed-text-v1";

          memory = {
            defaultScope = "project";
          };

          webServerEnabled = false;
          webServerPort = 4747;
          webServerHost = "127.0.0.1";

          autoCaptureEnabled = true;
          autoCaptureLanguage = "auto";

          showAutoCaptureToasts = true;
          showUserProfileToasts = true;
          showErrorToasts = true;

          userProfileAnalysisInterval = 10;
          userProfileMaxContextBytes = 32768;
          maxMemories = 25;

          compaction = {
            enabled = true;
            memoryLimit = 10;
          };

          chatMessage = {
            enabled = true;
            maxMemories = 3;
            excludeCurrentSession = true;
            injectOn = "first";
          };
        };
      in
      {
        hdwlinux.programs.opencode.plugins = [
          "opencode-mem"
        ];

        files.".config/opencode/opencode-mem.jsonc".text = builtins.toJSON opencodeMemConfig;
      };
  };

  config.substrate.modules.programs.opencode.ponytail = {
    tags = [
      "ai:clients"
    ];

    perUser = {
      hdwlinux.programs.opencode.plugins = [
        "@dietrichgebert/ponytail"
      ];
    };
  };

  config.substrate.modules.programs.opencode.oh-my-opencode-slim = {
    tags = [
      "ai:clients"
    ];

    perUser =
      { config, pkgs, lib, ... }:
      let
        # Resolve an alias to its ordered "provider/model" fallback chain consumed by
        # oh-my-opencode-slim. First entry is the primary model.
        resolveAliases =
          aliasName:
          let
            alias = config.hdwlinux.ai.clients.models.aliases.${aliasName};
          in
          map (m: "${m.provider}/${m.model}") alias.models;

        # A single host-aware preset: aliases resolve to opencode-go models on personal
        # hosts and grove models on the work host, so no per-host preset switching is needed
        hdwlinux = {
          orchestrator = {
            model = resolveAliases "orchestration";
          };
          oracle = {
            model = resolveAliases "analysis";
          };
          librarian = {
            model = resolveAliases "research";
            mcps = [
              "context7"
              "gh_grep"
            ];
          };
          explorer = {
            model = resolveAliases "fast";
          };
          designer = {
            model = resolveAliases "balanced";
          };
          fixer = {
            model = resolveAliases "coding";
          };
          observer = {
            model = resolveAliases "writing";
          };
        };
      in
      {
        packages = [
          (pkgs.writeShellApplication {
            name = "omos";
            runtimeInputs = [ pkgs.python3 ];
            text = builtins.readFile ./omos.sh;
          })
        ];

        hdwlinux.programs.opencode.plugins = [
          "oh-my-opencode-slim@beta"
        ];

        files.".config/opencode/oh-my-opencode-slim.json".text = builtins.toJSON {
          multiplexer = {
            type = "auto";
            layout = "main-vertical";
            main_pane_size = 60;
          };
          preset = "hdwlinux";
          disabled_agents = [ ];
          presets = {
            hdwlinux = hdwlinux;
          };
        };
      };
  };
}
