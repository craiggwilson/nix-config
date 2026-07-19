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
        ...
      }:
      let
        # Resolve an alias to "provider/model" format for OpenCode
        resolveAlias =
          aliasName:
          let
            alias = config.hdwlinux.ai.clients.models.aliases.${aliasName};
          in
          "${alias.provider}/${alias.model}";

        # Transform tools attrset for OpenCode config (boolean values)
        # "allow" -> true, "ask"/"deny" -> false
        transformTools = tools: lib.mapAttrs (_: perm: perm == "allow") tools;

        agentConfig = lib.mapAttrs (
          name: agent:
          {
            inherit (agent) color description mode;
            model = resolveAlias agent.model;
            prompt = "{file:${config.home.homeDirectory}/.config/opencode/prompts/agents/${name}.md}";
            inherit (agent) temperature;
          }
          // lib.optionalAttrs (agent.tools != { }) { tools = transformTools agent.tools; }
        ) config.hdwlinux.ai.clients.agents;

        commandConfig = lib.mapAttrs (name: command: {
          inherit (command) description;
          template = "{file:${config.home.homeDirectory}/.config/opencode/prompts/commands/${name}.md}";
        }) config.hdwlinux.ai.clients.commands;

        ruleInstructions = lib.mapAttrsToList (
          name: _rule: "${config.home.homeDirectory}/.config/opencode/prompts/rules/${name}.md"
        ) config.hdwlinux.ai.clients.rules;

        # Provider metadata: OpenCode-specific configuration for each provider
        # Note: augment provider is handled by programs.opencode-augment-provider below
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
        ) (lib.filterAttrs (k: _: providerMeta ? ${k}) config.hdwlinux.ai.clients.models.providers);

        # Opencode theme derived from the active hdwlinux theme colors
        opencodeTheme = import ./_theme.nix config.hdwlinux.theme.colors;

        # opencode-ensemble plugin directory in the nix store
        ensemblePluginDir = "${pkgs.callPackage ./plugins/_ensemble.nix { }}/lib/opencode-ensemble";

        # Derive ponytail source from the skill path set by the ponytail skills module,
        # avoiding a duplicate fetch.
        # ponytail: null-safe guard — if the skill module isn't loaded, skip the plugin.
        ponytailBaseDir =
          let
            skillPath = config.hdwlinux.ai.clients.skills.ponytail or null;
          in
          if skillPath != null then builtins.dirOf (builtins.dirOf skillPath) else null;

      in
      {
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

          # MCP servers are picked up from programs.mcp.servers, which is
          # populated by modules/ai/clients/default.nix from hdwlinux.ai.clients.mcpServers
          enableMcpIntegration = true;

          themes.hdwlinux = opencodeTheme;

          tui = {
            theme = "hdwlinux";
            keybinds = {
              "app_exit" = "ctrl+q";
            };
          };

          skills = config.hdwlinux.ai.clients.skills;

          settings = {
            provider = providers;
            agent = agentConfig;
            command = commandConfig;
            instructions = ruleInstructions;
            permission = config.hdwlinux.ai.clients.tools;
            small_model = resolveAlias "fast";
            plugin = [
              "file://${ensemblePluginDir}"
            ]
            ++ lib.optionals (ponytailBaseDir != null) [
              "file://${ponytailBaseDir}/.opencode/plugins/ponytail.mjs"
            ];
          };
        };

        # opencode-projects plugin: delegates plugin registration to the dedicated HM module.
        programs.opencode-projects.enable = true;
      };
  };

  config.substrate.modules.programs.opencode.augment = {
    tags = [
      "ai:clients"
      "users:craig:work"
    ];

    homeManager =
      {
        config,
        lib,
        ...
      }:
      {
        # Augment provider: delegates provider registration to the dedicated HM module.
        # Models are transformed from hdwlinux provider format to OpenCode format.
        programs.opencode-augment-provider = {
          enable = true;
          models = lib.mapAttrs (slug: model: {
            name = model.displayName;
            limit = {
              context = model.limits.context;
              output = model.limits.output;
            };
          }) config.hdwlinux.ai.clients.models.providers.augment.models;
        };
      };
  };
}
