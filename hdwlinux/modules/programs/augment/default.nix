{
  config.substrate.modules.programs.augment = {
    tags = [
      "ai:agent"
      "users:craig:work"
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Generate YAML frontmatter from extraMeta attrset (for commands/rules)
        extraMetaToFrontmatter =
          extraMeta:
          lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value: "${key}: ${value}") extraMeta);

        # Format tools attrset as comma-separated string (just the tool names)
        formatTools = tools: lib.concatStringsSep ", " (lib.attrNames tools);

        # Generate agent markdown with formal fields + any extra metadata
        generateAgentMd =
          name: agent:
          let
            # Build frontmatter from formal fields
            formalFields = [
              "name: ${name}"
              "description: ${agent.description}"
              "model: ${agent.model}"
              "tools: ${formatTools agent.tools}"
            ];
            # Add any extra metadata fields
            extraFields = lib.mapAttrsToList (key: value: "${key}: ${value}") agent.extraMeta;
            allFields = formalFields ++ extraFields;
            frontmatter = ''
              ---
              ${lib.concatStringsSep "\n" allFields}
              ---

            '';
            content = builtins.readFile agent.content;
          in
          pkgs.writeText "${name}.md" (frontmatter + content);

        # Generate markdown with frontmatter from description + extraMeta (for commands/rules)
        generateMd =
          name: item:
          let
            # Build frontmatter from description + any extra metadata fields
            descriptionField = "description: ${item.description}";
            extraFields = extraMetaToFrontmatter item.extraMeta;
            allFields = if extraFields == "" then descriptionField else "${descriptionField}\n${extraFields}";
            frontmatter = ''
              ---
              ${allFields}
              ---

            '';
            content = builtins.readFile item.content;
          in
          pkgs.writeText "${name}.md" (frontmatter + content);

        # Build a derivation containing all agent markdown files
        agentsDir = pkgs.runCommand "augment-agents" { } ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: agent: "cp ${generateAgentMd name agent} $out/${name}.md"
            ) config.hdwlinux.ai.agent.agents
          )}
        '';

        # Build a derivation containing all command markdown files
        commandsDir = pkgs.runCommand "augment-commands" { } ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: command: "cp ${generateMd name command} $out/${name}.md"
            ) config.hdwlinux.ai.agent.commands
          )}
        '';

        # Build a derivation containing all rule markdown files
        rulesDir = pkgs.runCommand "augment-rules" { } ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: rule: "cp ${generateMd name rule} $out/${name}.md"
            ) config.hdwlinux.ai.agent.rules
          )}
        '';

        # Build a derivation containing all skills
        skillsDir = pkgs.runCommand "augment-skills" { } ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: path: "cp -r ${path} $out/${name}") config.hdwlinux.ai.agent.skills
          )}
        '';

        # Transform MCP servers to Augment format
        mcpServers = lib.mapAttrs (
          name: server:
          if server ? stdio then
            {
              command = server.stdio.command;
              args = server.stdio.args;
            }
          else if server ? http then
            {
              url = server.http.url;
              headers = server.http.headers;
            }
          else
            throw "Unknown MCP server type for ${name}"
        ) (lib.filterAttrs (n: _: n != "augment-context-engine") config.hdwlinux.ai.agent.mcpServers);

      in
      {
        home.packages = [
          (pkgs.writeShellScriptBin "auggie" ''
            ${pkgs.hdwlinux.auggie}/bin/auggie --mcp-config ~/.augment/mcp-servers.json "$@"
          '')
        ];

        home.file = {
          ".augment/agents".source = agentsDir;
          ".augment/commands".source = commandsDir;
          ".augment/rules".source = rulesDir;
          ".augment/skills".source = skillsDir;
          ".augment/mcp-servers.json".text = builtins.toJSON { inherit mcpServers; };
        };

        programs.vscode.profiles.default.userSettings = lib.mkIf config.programs.vscode.enable {
          "github.copilot.enable" = {
            "*" = false;
          };
        };
      };
  };
}
