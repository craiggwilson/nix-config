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
        ...
      }:
      let
        # Mapping from canonical model names to OpenCode model IDs
        # LLM models use their name directly as the ID
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
        }
        // lib.mapAttrs (_: _: null) (config.hdwlinux.ai.llm.models or { });

        # Get all models resolved with OpenCode-specific names
        # For LLM models, use the model name as the ID (null in opencodeModelIds means use the key)
        resolvedModels = config.hdwlinux.ai.agent.resolveModels (
          name:
          let
            mapped = opencodeModelIds.${name} or "not-found";
          in
          if mapped == "not-found" then
            null
          else if mapped == null then
            name
          else
            mapped
        );

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

        # Provider metadata: how to configure each provider for OpenCode
        providerMeta = {
          augment = {
            npm = "file://${pkgs.hdwlinux.opencode-augment-provider}/lib/node_modules/opencode-augment-provider";
            name = "Augment Code";
            transformModel = displayName: model: {
              name = displayName;
              limit = {
                context = model.limits.context;
                output = model.limits.output;
              };
            };
          };

          "llama.cpp" = {
            npm = "@ai-sdk/openai-compatible";
            name = "LLaMA C++ (local)";
            options = lib.optionalAttrs (config.hdwlinux ? services.llama-cpp) {
              baseURL = "http://${config.hdwlinux.services.llama-cpp.host}:${toString config.hdwlinux.services.llama-cpp.port}/v1";
            };
            transformModel =
              displayName: model:
              let
                llmModel = config.hdwlinux.ai.llm.models.${displayName} or { };
                oc = llmModel.settings.opencode or { };
              in
              {
                name = oc.name or displayName;
                limit = {
                  context = model.limits.context;
                  output = model.limits.output;
                };
              }
              // lib.optionalAttrs (oc ? reasoning) { inherit (oc) reasoning; }
              // lib.optionalAttrs (oc ? tool_call) { inherit (oc) tool_call; };
          };
        };

        # Group resolved models by provider
        modelsByProvider = lib.foldlAttrs (
          acc: displayName: model:
          lib.foldl' (
            innerAcc: provider:
            innerAcc
            // {
              ${provider} = (innerAcc.${provider} or { }) // {
                ${displayName} = model;
              };
            }
          ) acc model.providers
        ) { } resolvedModels;

        # Build providers config from models grouped by provider
        providers = lib.mapAttrs (
          providerName: models:
          let
            meta = providerMeta.${providerName};
          in
          {
            inherit (meta) npm name;
          }
          // lib.optionalAttrs (meta ? options && meta.options != { }) { inherit (meta) options; }
          // {
            models = lib.mapAttrs' (
              displayName: model: lib.nameValuePair model.name (meta.transformModel displayName model)
            ) models;
          }
        ) modelsByProvider;

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
        };

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
