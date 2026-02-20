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
        resolveModel = config.hdwlinux.ai.agent.resolveModel "opencode";

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
          // (lib.optionalAttrs (config.hdwlinux.services ? llama-cpp) {
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
            augment = {
              npm = "file://${pkgs.hdwlinux.opencode-augment-provider}/lib/node_modules/opencode-augment-provider";
              name = "Augment Code";
              models = {
                "claude-haiku-4-5" = {
                  name = "Claude Haiku 4.5";
                  limit = {
                    context = 200000;
                    output = 8000;
                  };
                };
                "claude-opus-4-6" = {
                  name = "Claude Opus 4.6";
                  limit = {
                    context = 200000;
                    output = 32000;
                  };
                };
                "claude-opus-4-5" = {
                  name = "Claude Opus 4.5";
                  limit = {
                    context = 200000;
                    output = 32000;
                  };
                };
                "claude-sonnet-4" = {
                  name = "Claude Sonnet 4";
                  limit = {
                    context = 200000;
                    output = 16000;
                  };
                };
                "claude-sonnet-4-5" = {
                  name = "Claude Sonnet 4.5";
                  limit = {
                    context = 200000;
                    output = 16000;
                  };
                };
                "gpt-5-1" = {
                  name = "GPT 5.1";
                  limit = {
                    context = 400000;
                    output = 32000;
                  };
                };
                "gpt-5-2" = {
                  name = "GPT 5.2";
                  limit = {
                    context = 400000;
                    output = 32000;
                  };
                };
              };
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
          small_model = "augment/claude-haiku-4-5";
          plugin = [
            #"file://${pkgs.hdwlinux.opencode-projects-plugin}/lib/node_modules/opencode-projects"
          ];
          keybinds = {
            "app_exit" = "ctrl+q";
          };
        }
        // lib.optionalAttrs (hasTag "ai:llm") { provider = providers; };

      in
      {
        hdwlinux.ai.agent.models = {
          "haiku4.5".providers.opencode = "augment/claude-haiku-4-5";
          "opus4.5".providers.opencode = "augment/claude-opus-4-5";
          "opus4.6".providers.opencode = "augment/claude-opus-4-6";
          "sonnet4".providers.opencode = "augment/claude-sonnet-4";
          "sonnet4.5".providers.opencode = "augment/claude-sonnet-4-5";
          "gpt5.1".providers.opencode = "augment/gpt-5-1";
          "gpt5.2".providers.opencode = "augment/gpt-5-2";
        };

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
