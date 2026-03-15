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
        toAuggieSlug =
          slug:
          let
            parts = lib.splitString "-" slug;
            isNumeric = s: builtins.match "[0-9]+" s != null;
            knownProviders = [
              "claude"
              "gpt"
              "gemini"
            ];
            hasKnownProvider = builtins.any (p: (builtins.head parts) == p) knownProviders;
            versionParts = lib.filter isNumeric parts;
            nonVersionParts = lib.filter (s: !isNumeric s) parts;
            majorVersion = if versionParts != [ ] then builtins.head versionParts else null;
            baseName = lib.concatStringsSep "" nonVersionParts;
          in
          if hasKnownProvider then baseName + (if majorVersion != null then majorVersion else "") else slug;
        # Look up a hex color (with #) in the theme's derived ANSI name map.
        # Returns the Augment ANSI color name, or null if no match.
        ansiColorNameFromHex = hex: config.hdwlinux.theme.colors.withHashtag.hexToAnsiName hex;

        # Resolve an alias name to an Augment-compatible model slug.
        resolveModelSlug =
          aliasName:
          let
            alias = config.hdwlinux.ai.agent.models.aliases.${aliasName};
          in
          toAuggieSlug alias.model;

        formatTools = tools: lib.concatStringsSep ", " (lib.attrNames tools);

        generateAgentMd =
          name: agent:
          let
            augmentColor = ansiColorNameFromHex agent.color;
            formalFields = [
              "name: ${name}"
              "description: ${agent.description}"
              "model: ${resolveModelSlug agent.model}"
              "tools: ${formatTools agent.tools}"
            ]
            ++ lib.optional (augmentColor != null) "color: ${augmentColor}";
            frontmatter = ''
              ---
              ${lib.concatStringsSep "\n" formalFields}
              ---

            '';
            content = builtins.readFile agent.prompt;
          in
          pkgs.writeText "${name}.md" (frontmatter + content);

        generateRuleMd =
          name: rule:
          let
            augmentType = if rule.loadMode == "always" then "always_apply" else "agent_requested";
            frontmatter = ''
              ---
              description: ${rule.description}
              type: ${augmentType}
              ---

            '';
            content = builtins.readFile rule.prompt;
          in
          pkgs.writeText "${name}.md" (frontmatter + content);

        generateCommandMd =
          name: command:
          let
            frontmatter = ''
              ---
              description: ${command.description}
              argument-hint: ${command.argumentHint}
              ---

            '';
            content = builtins.readFile command.prompt;
          in
          pkgs.writeText "${name}.md" (frontmatter + content);

        agentsDir = pkgs.linkFarm "augment-agents" (
          lib.mapAttrsToList (name: agent: {
            name = "${name}.md";
            path = generateAgentMd name agent;
          }) config.hdwlinux.ai.agent.agents
        );

        commandsDir = pkgs.linkFarm "augment-commands" (
          lib.mapAttrsToList (name: command: {
            name = "${name}.md";
            path = generateCommandMd name command;
          }) config.hdwlinux.ai.agent.commands
        );

        rulesDir = pkgs.linkFarm "augment-rules" (
          lib.mapAttrsToList (name: rule: {
            name = "${name}.md";
            path = generateRuleMd name rule;
          }) config.hdwlinux.ai.agent.rules
        );

        skillsDir = pkgs.linkFarm "augment-skills" (
          lib.mapAttrsToList (name: path: {
            inherit name path;
          }) config.hdwlinux.ai.agent.skills
        );

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

      };
  };
}
