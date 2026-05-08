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

        # Transform agents to OpenCode JSON config format
        # Uses {file:path} syntax for OpenCode's variable substitution
        agentConfig = lib.mapAttrs (
          _: agent:
          {
            color = agent.color;
            description = agent.description;
            mode = agent.mode;
            model = resolveAlias agent.model;
            prompt = "{file:${builtins.unsafeDiscardStringContext (toString agent.prompt)}}";
            temperature = agent.temperature;
          }
          // lib.optionalAttrs (agent.tools != { }) { tools = transformTools agent.tools; }
        ) config.hdwlinux.ai.clients.agents;

        # Transform commands to OpenCode JSON config format
        # Uses {file:path} syntax for OpenCode's variable substitution
        commandConfig = lib.mapAttrs (_: command: {
          description = command.description;
          template = "{file:${builtins.unsafeDiscardStringContext (toString command.prompt)}}";
        }) config.hdwlinux.ai.clients.commands;

        # Collect all rules as direct file paths for OpenCode's instructions config
        # Uses absolute paths to source files in the nix store
        ruleInstructions = lib.mapAttrsToList (
          _: rule: builtins.unsafeDiscardStringContext (toString rule.prompt)
        ) config.hdwlinux.ai.clients.rules;

        # Provider metadata: OpenCode-specific configuration for each provider
        providerMeta = {
          augment = {
            npm = "file://${config.home.homeDirectory}/Projects/opencode/opencode-augment-provider";
          };

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

        # opencode-ensemble plugin directory in the nix store
        ensemblePluginDir = "${pkgs.callPackage ./plugins/_ensemble.nix { }}/lib/opencode-ensemble";

        # opencode-skill-creator plugin and skill directories in the nix store
        skillCreatorPkg = pkgs.callPackage ./plugins/_skill-creator.nix { };
        skillCreatorPluginDir = "${skillCreatorPkg}/lib/opencode-skill-creator";
        skillCreatorSkillDir = "${skillCreatorPkg}/lib/opencode-skill-creator/skill";

      in
      {
        home.packages = [
          pkgs.opencode-desktop
        ];

        programs.opencode = {
          enable = true;

          # MCP servers are picked up from programs.mcp.servers, which is
          # populated by modules/ai/clients/default.nix from hdwlinux.ai.clients.mcpServers
          enableMcpIntegration = true;

          # Skills from hdwlinux.ai.clients.skills are store path strings pointing
          # to directories; the HM module symlinks them as skill/<name>/ recursively.
          # opencode discovers from both skill/ and skills/ via glob alternation.
          skills = config.hdwlinux.ai.clients.skills // {
            skill-creator = skillCreatorSkillDir;
          };

          settings = {
            tui.theme = "system";
            provider = providers;
            agent = agentConfig;
            command = commandConfig;
            instructions = ruleInstructions;
            permission = config.hdwlinux.ai.clients.tools;
            small_model = resolveAlias "fast";
            plugin = [
              "file://${skillCreatorPluginDir}"
              "file://${ensemblePluginDir}"
              "file://${config.home.homeDirectory}/Projects/opencode/opencode-projects-plugin"
              #"file://${mestraPluginDir}"
            ];
            keybinds = {
              "app_exit" = "ctrl+q";
            };
          };
        };
      };
  };
}
