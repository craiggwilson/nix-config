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

        # Format tools attrset for OpenCode frontmatter (lowercase names, boolean values)
        # "allow" -> true, "ask"/"deny" -> false
        formatTools =
          tools:
          let
            toolLines = lib.mapAttrsToList (
              name: perm: "  ${lib.toLower name}: ${if perm == "allow" then "true" else "false"}"
            ) tools;
          in
          lib.concatStringsSep "\n" toolLines;

        # Generate agent markdown with OpenCode-compatible frontmatter
        generateAgentMd =
          name: agent:
          let
            toolsSection = if agent.tools == { } then "" else "tools:\n${formatTools agent.tools}\n";
            frontmatter = ''
              ---
              description: ${agent.description}
              mode: ${agent.mode}
              model: ${agent.model}
              ${toolsSection}---

            '';
            content = builtins.readFile agent.content;
          in
          pkgs.writeText "${name}.md" (frontmatter + content);

        # Generate command markdown with OpenCode-compatible frontmatter
        generateCommandMd =
          name: command:
          let
            frontmatter = ''
              ---
              description: ${command.description}
              ---

            '';
            content = builtins.readFile command.content;
          in
          pkgs.writeText "${name}.md" (frontmatter + content);

        # Build a derivation containing all agent markdown files
        agentsDir = pkgs.runCommand "opencode-agents" { } ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: agent: "cp ${generateAgentMd name agent} $out/${name}.md"
            ) config.hdwlinux.ai.agent.agents
          )}
        '';

        # Build a derivation containing all command markdown files
        commandsDir = pkgs.runCommand "opencode-commands" { } ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: command: "cp ${generateCommandMd name command} $out/${name}.md"
            ) config.hdwlinux.ai.agent.commands
          )}
        '';

        # Build a derivation containing all skills in OpenCode format
        # OpenCode expects: skills/<name>/SKILL.md
        skillsDir = pkgs.runCommand "opencode-skills" { } ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: path: ''
              mkdir -p $out/${name}
              cp -r ${path}/* $out/${name}/
            '') config.hdwlinux.ai.agent.skills
          )}
        '';

        # Collect all rules into instruction file paths for the config
        ruleInstructions = lib.mapAttrsToList (
          name: _rule: ".config/opencode/rules/${name}.md"
        ) config.hdwlinux.ai.agent.rules;

        # Generate rule files (no frontmatter needed for OpenCode - just content)
        rulesDir = pkgs.runCommand "opencode-rules" { } ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: rule: "cp ${rule.content} $out/${name}.md") config.hdwlinux.ai.agent.rules
          )}
        '';

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
              npm = "file://${pkgs.hdwlinux.opencode-augment}/lib/node_modules/@opencode/augment-provider";
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
          instructions = ruleInstructions;
          permission = config.hdwlinux.ai.agent.tools;
          plugin = [
            "file://${pkgs.hdwlinux.opencode-projects-plugin}/lib/node_modules/opencode-projects"
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
          ".config/opencode/agents".source = agentsDir;
          ".config/opencode/commands".source = commandsDir;
          ".config/opencode/skills".source = skillsDir;
          ".config/opencode/rules".source = rulesDir;
        };
      };
  };
}
