{
  config.substrate.modules.programs.opencode = {
    tags = [
      "ai:agent"
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
            alias = config.hdwlinux.ai.agent.models.aliases.${aliasName};
          in
          "${alias.provider}/${alias.model}";

        # Transform MCP servers to OpenCode format
        mcpConfig = lib.mapAttrs (
          name: server:
          if server ? stdio then
            {
              type = "local";
              command = [ server.stdio.command ] ++ server.stdio.args;
              enabled = true;
            }
          else if server ? http then
            {
              type = "remote";
              url = server.http.url;
              headers = server.http.headers;
              enabled = true;
            }
          else
            throw "Unknown MCP server type for ${name}"
        ) config.hdwlinux.ai.agent.mcpServers;

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
        ) config.hdwlinux.ai.agent.agents;

        # Transform commands to OpenCode JSON config format
        # Uses {file:path} syntax for OpenCode's variable substitution
        commandConfig = lib.mapAttrs (_: command: {
          description = command.description;
          template = "{file:${builtins.unsafeDiscardStringContext (toString command.prompt)}}";
        }) config.hdwlinux.ai.agent.commands;

        # Build a derivation containing symlinks to all skills
        # OpenCode expects: skills/<name>/SKILL.md (must be files for discovery)
        skillsDir = pkgs.linkFarm "opencode-skills" (
          lib.mapAttrsToList (name: path: {
            inherit name;
            path = path;
          }) config.hdwlinux.ai.agent.skills
        );

        # Collect all rules as direct file paths for OpenCode's instructions config
        # Uses absolute paths to source files in the nix store
        ruleInstructions = lib.mapAttrsToList (
          _: rule: builtins.unsafeDiscardStringContext (toString rule.prompt)
        ) config.hdwlinux.ai.agent.rules;

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

        # Build providers config from hdwlinux.ai.agent.models.providers
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
        ) (lib.filterAttrs (k: _: providerMeta ? ${k}) config.hdwlinux.ai.agent.models.providers);

        # oh-my-opencode-slim plugin directory in the nix store
        ohMyOpencodeSlimDir = "${pkgs.hdwlinux.oh-my-opencode-slim}/lib/oh-my-opencode-slim";

        # oh-my-opencode-slim plugin configuration
        ohMyOpencodeSlimConfig = {
          "$schema" = "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json";
          preset = "augment";
          # MCP servers are managed by Nix; disable plugin-installed ones
          disabled_mcps = [
            "context7"
            "grep_app"
            "websearch"
          ];
          presets = {
            augment = {
              orchestrator = {
                model = resolveAlias "balanced";
                skills = [ ];
                mcps = [ "*" ];
              };
              oracle = {
                model = resolveAlias "analyst";
                skills = [ ];
                mcps = [ ];
              };
              librarian = {
                model = resolveAlias "balanced";
                skills = [ ];
                mcps = [ "*" ];
              };
              explorer = {
                model = resolveAlias "fast";
                skills = [ ];
                mcps = [ ];
              };
              designer = {
                model = resolveAlias "coder";
                skills = [ ];
                mcps = [ ];
              };
              fixer = {
                model = resolveAlias "fast";
                skills = [ ];
                mcps = [ ];
              };
            };
          };
          # tmux is the default terminal; enable pane spawning for sub-agents
          tmux = {
            enabled = true;
            layout = "main-vertical";
            main_pane_size = 60;
          };
        };

        # OpenCode configuration
        opencodeConfig = {
          "$schema" = "https://opencode.ai/config.json";
          provider = providers;
          mcp = mcpConfig;
          agent = agentConfig;
          command = commandConfig;
          instructions = ruleInstructions;
          permission = config.hdwlinux.ai.agent.tools;
          small_model = resolveAlias "fast";
          plugin = [
            "file://${ohMyOpencodeSlimDir}"
          ];
          keybinds = {
            "app_exit" = "ctrl+q";
          };
        };

      in
      {
        home.packages = [
          pkgs.opencode
          pkgs.beads
        ];

        home.file = {
          ".config/opencode/opencode.json".text = builtins.toJSON opencodeConfig;
          ".config/opencode/oh-my-opencode-slim.json".text = builtins.toJSON ohMyOpencodeSlimConfig;
          ".config/opencode/skills".source = skillsDir;
        };
      };
  };
}
