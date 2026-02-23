{
  config.substrate.modules.programs.opencode = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      {
        inputs,
        config,
        lib,
        pkgs,
        hasTag,
        ...
      }:
      let
        # Mapping from canonical model names to OpenCode model IDs (provider/model-id format)
        opencodeModelIds = {
          "Claude Haiku 4.5" = "claude-haiku-4-5";
          "Claude Opus 4.5" = "claude-opus-4-5";
          "Claude Opus 4.6" = "claude-opus-4-6";
          "Claude Sonnet 4" = "claude-sonnet-4";
          "Claude Sonnet 4.5" = "claude-sonnet-4-5";
          "Claude Sonnet 4.6" = "claude-sonnet-4-6";
          "GPT 5" = "gpt-5";
          "GPT 5.1" = "gpt-5-1";
          "GPT 5.2" = "gpt-5-2";
        };

        # Get all models resolved with OpenCode-specific names
        resolvedModels = config.hdwlinux.ai.agent.resolveModels (name: opencodeModelIds.${name} or null);

        # Resolve a single model name to an OpenCode model ID
        resolveModel =
          modelName:
          let
            resolved = resolvedModels.${modelName} or null;
          in
          if resolved == null then
            throw "Model ${modelName} is not available for opencode"
          else
            resolved.name;

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
            description = agent.description;
            mode = agent.mode;
            model = resolveModel agent.model;
            prompt = "{file:${builtins.unsafeDiscardStringContext (toString agent.prompt)}}";
          }
          // lib.optionalAttrs (agent.tools != { }) { tools = transformTools agent.tools; }
          // lib.optionalAttrs (agent.extraMeta ? color) { color = agent.extraMeta.color; }
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

        providers =
          { }
          // (lib.optionalAttrs (config.hdwlinux ? services ? llama-cpp) {
            "llama.cpp" = {
              npm = "@ai-sdk/openai-compatible";
              name = "LLaMA C++ (local)";
              options = {
                baseURL = "http://${config.hdwlinux.services.llama-cpp.host}:${lib.toString config.hdwlinux.services.llama-cpp.port}/v1";
              };
              models = lib.mapAttrs (
                _: v: { name = v.name; } // (v.settings.opencode or { })
              ) config.hdwlinux.ai.llm.models;
            };
          })
          // (lib.optionalAttrs (hasTag "users:craig:work") {
            augment =
              let
                # Filter to only models with "augment" provider and transform to opencode format
                augmentModels = lib.filterAttrs (
                  _: model: builtins.elem "augment" model.providers
                ) resolvedModels;

                # Transform to opencode format: key is the model ID part after "augment/"
                models = lib.mapAttrs' (
                  displayName: model:
                  lib.nameValuePair model.name {
                    name = displayName;
                    limit = {
                      context = model.limits.context;
                      output = model.limits.output;
                    };
                  }
                ) augmentModels;
              in
              {
                npm = "file://${pkgs.hdwlinux.opencode-augment-provider}/lib/node_modules/opencode-augment-provider";
                name = "Augment Code";
                inherit models;
              };
          });

        # OpenCode configuration
        opencodeConfig = {
          "$schema" = "https://opencode.ai/config.json";
          provider = providers;
          mcp = mcpConfig;
          agent = agentConfig;
          command = commandConfig;
          instructions = ruleInstructions;
          permission = config.hdwlinux.ai.agent.tools;
          small_model = resolveModel "small";
          plugin = [
            "file://${config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/packages/opencode-projects-plugin"}"
          ];
          keybinds = {
            "app_exit" = "ctrl+q";
          };
        }
        // lib.optionalAttrs (hasTag "ai:llm") { provider = providers; };

      in
      {
        home.packages = [
          inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode
          pkgs.beads
        ];

        home.file = {
          ".config/opencode/opencode.json".text = builtins.toJSON opencodeConfig;
          ".config/opencode/skills".source = skillsDir;
        };
      };
  };
}
