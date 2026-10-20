{
  config.substrate.modules.programs.opencode = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        wrap,
        ...
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

        # Primary "provider/model" for single-model consumers (agent definitions, title)
        resolveAlias = aliasName: lib.head (resolveAliases aliasName);

        # Transform agent-level tool toggles into opencode v2 permissions
        # entries: "allow" -> allow, anything else -> deny.
        transformTools =
          tools:
          lib.mapAttrsToList (name: perm: {
            action = name;
            resource = "*";
            effect = if perm == "allow" then "allow" else "deny";
          }) tools;

        # v2 renames: bash -> shell, task -> subagent; write merges into edit.
        renameAction =
          name:
          {
            bash = "shell";
            task = "subagent";
            write = "edit";
          }
          .${name} or name;

        # Convert the v1-style grouped permission map (tool -> "allow"/"ask"/"deny"
        # or pattern -> permission) into opencode v2's ordered permissions array of
        # { action, resource, effect }. Specific patterns come before "*" so the
        # wildcard can't shadow them.
        permissionArray =
          tools:
          let
            entries = lib.flatten (
              lib.mapAttrsToList (
                action: value:
                let
                  action' = renameAction action;
                in
                if builtins.isString value then
                  [
                    {
                      action = action';
                      resource = "*";
                      effect = value;
                    }
                  ]
                else
                  lib.mapAttrsToList (resource: effect: {
                    action = action';
                    inherit resource effect;
                  }) value
              ) tools
            );
            split = lib.partition (e: e.resource == "*") entries;
          in
          lib.unique (split.wrong ++ split.right);

        agentConfig = lib.mapAttrs (
          name: agent:
          {
            inherit (agent) color description mode;
            model = resolveAlias agent.model;
            system = "{file:${config.home.homeDirectory}/.config/opencode/prompts/agents/${name}.md}";
            request.body.temperature = agent.temperature;
          }
          // lib.optionalAttrs (agent.tools != { }) { permissions = transformTools agent.tools; }
        ) config.hdwlinux.ai.clients.agents;

        commandConfig = lib.mapAttrs (name: command: {
          inherit (command) description;
          template = "{file:${config.home.homeDirectory}/.config/opencode/prompts/commands/${name}.md}";
        }) config.hdwlinux.ai.clients.commands;

        ruleInstructions = lib.mapAttrsToList (
          name: _rule: "${config.home.homeDirectory}/.config/opencode/prompts/rules/${name}.md"
        ) config.hdwlinux.ai.clients.rules;

        # Provider metadata: OpenCode-specific configuration for each provider
        providerMeta = {
          "llama.cpp" = {
            package = "aisdk:@ai-sdk/openai-compatible";
            settings = lib.optionalAttrs (config.hdwlinux ? services.llama-cpp) {
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
                modelID = slug;
                name = model.displayName;
                limit = {
                  context = model.limits.context;
                  output = model.limits.output;
                };
              }
              // lib.optionalAttrs (oc ? tool_call) { capabilities.tools = oc.tool_call; };
          };
        };

        # Build providers config from hdwlinux.ai.clients.models.providers
        # Only include providers that have metadata and at least one model —
        # a provider with metadata but no models (e.g. grove on personal
        # hosts) would render as an empty entry.
        providers =
          lib.mapAttrs
            (
              providerKey: provider:
              let
                # Provider modules can carry their own OpenCode wiring
                # (settings.opencode); the static metadata below covers the
                # providers that don't.
                meta = providerMeta.${providerKey} or (provider.settings.opencode or { });
                transformModel =
                  meta.transformModel or (slug: model: {
                    modelID = slug;
                    name = model.displayName;
                    limit = {
                      context = model.limits.context;
                      output = model.limits.output;
                    };
                  });
              in
              lib.filterAttrs (_: value: value != null) {
                package = meta.package or null;
                name = provider.displayName;
                models = lib.mapAttrs (slug: model: transformModel slug model) provider.models;
              }
              // lib.optionalAttrs (meta ? settings && meta.settings != { }) { inherit (meta) settings; }
              // lib.optionalAttrs (meta ? headers && meta.headers != { }) { inherit (meta) headers; }
              // lib.optionalAttrs (meta ? env && meta.env != [ ]) { inherit (meta) env; }
            )
            (
              lib.filterAttrs (_: p: p.models != { }) (
                lib.filterAttrs (
                  k: p: providerMeta ? ${k} || p.settings ? opencode
                ) config.hdwlinux.ai.clients.models.providers
              )
            );

        # Opencode theme derived from the active hdwlinux theme colors
        opencodeTheme = import ./_theme.nix config.hdwlinux.theme.colors;

        # OpenCode reads {env:NAME} from its own environment, so a secret header
        # is spelled that way here and the launcher below supplies the value.
        # The registry records only that a secret is needed; this is where that
        # becomes OpenCode's syntax.
        mcpHeaders =
          headers:
          lib.mapAttrs (
            _: value: if builtins.isString value then value else "${value.prefix}{env:${value.secret}}"
          ) headers;

        mcpServers = lib.mapAttrs (
          _: server:
          if server ? stdio then
            {
              type = "local";
              command = [ server.stdio.command ] ++ server.stdio.args;
            }
          else
            lib.filterAttrs (_: value: value != { }) {
              type = "remote";
              url = server.http.url;
              headers = mcpHeaders server.http.headers;
            }
        ) config.hdwlinux.ai.clients.mcpServers;

      in
      {
        # The launcher scope: every secret the MCP servers and model providers
        # reference, aggregated here so OpenCode's {env:...} substitution can
        # resolve them at exec time.
        secretspec.scopes.ai_clients_opencode.secrets =
          config.hdwlinux.ai.clients.mcpServersSecretNames ++ config.hdwlinux.ai.clients.providerSecretNames;
        home.packages = [
          pkgs.opencode-desktop
        ];

        xdg.configFile = lib.mkMerge [
          (lib.mapAttrs' (
            name: command: lib.nameValuePair "opencode/prompts/commands/${name}.md" { source = command.prompt; }
          ) config.hdwlinux.ai.clients.commands)
          (lib.mapAttrs' (
            name: rule: lib.nameValuePair "opencode/prompts/rules/${name}.md" { source = rule.prompt; }
          ) config.hdwlinux.ai.clients.rules)
          (lib.mapAttrs' (
            name: agent: lib.nameValuePair "opencode/prompts/agents/${name}.md" { source = agent.prompt; }
          ) config.hdwlinux.ai.clients.agents)
        ];

        programs.opencode = {
          enable = true;

          package = wrap.package {
            package = pkgs.opencode;
            name = "opencode";
            secrets.scope = "ai_clients_opencode";
          };

          # The MCP servers are rendered below rather than taken from
          # programs.mcp.servers, which cannot carry a secret header.
          enableMcpIntegration = false;

          themes.hdwlinux = opencodeTheme;

          skills = config.hdwlinux.ai.clients.skills;

          settings = {
            inherit providers;
            # v2 dropped small_model; the built-in title agent carries the fast model now.
            agents = agentConfig // {
              title.model = resolveAlias "fast";
            };
            commands = commandConfig;
            instructions = ruleInstructions;
            permissions = permissionArray config.hdwlinux.ai.clients.tools;
          }
          // lib.optionalAttrs (mcpServers != { }) {
            mcp.servers = mcpServers;
          };
        };
      };
  };

  config.substrate.modules.programs.opencode.opencode-mem = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      {
        config,
        lib,
        ...
      }:
      let
        # Use the primary model from the analysis alias so the memory plugin follows
        # the same host-specific provider routing as the rest of OpenCode.
        resolvePrimaryAlias =
          aliasName: lib.head config.hdwlinux.ai.clients.models.aliases.${aliasName}.models;

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
        programs.opencode.settings.plugins = [
          "opencode-mem"
        ];

        xdg.configFile."opencode/opencode-mem.jsonc" = {
          text = builtins.toJSON opencodeMemConfig;
        };
      };
  };

  config.substrate.modules.programs.opencode.ponytail = {
    tags = [
      "ai:clients"
    ];

    homeManager = {
      programs.opencode.settings.plugins = [
        "@dietrichgebert/ponytail"
      ];
    };
  };

  config.substrate.modules.programs.opencode.oh-my-opencode-slim = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      {
        config,
        pkgs,
        ...
      }:
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
        programs.opencode.settings.plugins = [
          "oh-my-opencode-slim@beta"
        ];

        xdg.configFile."opencode/oh-my-opencode-slim.json" = {
          text = builtins.toJSON {
            multiplexer = {
              type = "auto";
              layout = "main-vertical";
              main_pane_size = 60;
            };
            preset = "hdwlinux";
            disabled_agents = [ ];
            presets = {
              inherit hdwlinux;
            };
          };
        };
      };
  };
}
