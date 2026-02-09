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
        # Helper to get metadata value with default
        getMeta =
          item: key: default:
          item.metadata.${key} or default;

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

        # Generate agent markdown with OpenCode-compatible frontmatter
        generateAgentMd =
          name: agent:
          let
            frontmatter = ''
              ---
              description: ${getMeta agent "description" ""}
              mode: subagent
              model: ${getMeta agent "model" "opus4.5"}
              ---

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
              description: ${getMeta command "description" ""}
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

        # OpenCode configuration
        opencodeConfig = {
          "$schema" = "https://opencode.ai/config.json";
          mcp = mcpConfig;
          instructions = ruleInstructions;
        };

      in
      {
        home.packages = [ pkgs.opencode ];

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
