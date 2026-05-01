{
  config.substrate.modules.programs.augment = {
    tags = [
      "ai:clients"
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
        # Look up a hex color (with #) and return an Augment color name, or null.
        # Augment recognises 8 base names only, so bright variants collapse to base.
        ansiColorNameFromHex =
          hex:
          let
            slot = (config.hdwlinux.theme.colors.fromHex hex).ansi;
            # Strip "bright" prefix: brightBlue -> "blue", brightBlack -> "black".
            # The character after "bright" is always uppercase in our slot names.
            collapseSlot =
              s:
              let
                # e.g. "Blue" -> "blue"
                rest = builtins.substring 6 (builtins.stringLength s - 6) s;
                lower = {
                  A = "a";
                  B = "b";
                  C = "c";
                  D = "d";
                  E = "e";
                  F = "f";
                  G = "g";
                  H = "h";
                  I = "i";
                  J = "j";
                  K = "k";
                  L = "l";
                  M = "m";
                  N = "n";
                  O = "o";
                  P = "p";
                  Q = "q";
                  R = "r";
                  S = "s";
                  T = "t";
                  U = "u";
                  V = "v";
                  W = "w";
                  X = "x";
                  Y = "y";
                  Z = "z";
                };
                firstChar = builtins.substring 0 1 rest;
              in
              (lower.${firstChar} or firstChar) + builtins.substring 1 (builtins.stringLength rest - 1) rest;
          in
          if slot == null then
            null
          else if builtins.substring 0 6 slot == "bright" then
            collapseSlot slot
          else
            slot;

        # Resolve an alias name to an Augment-compatible model slug.
        resolveModelSlug =
          aliasName:
          let
            alias = config.hdwlinux.ai.clients.models.aliases.${aliasName};
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
          }) config.hdwlinux.ai.clients.agents
        );

        commandsDir = pkgs.linkFarm "augment-commands" (
          lib.mapAttrsToList (name: command: {
            name = "${name}.md";
            path = generateCommandMd name command;
          }) config.hdwlinux.ai.clients.commands
        );

        rulesDir = pkgs.linkFarm "augment-rules" (
          lib.mapAttrsToList (name: rule: {
            name = "${name}.md";
            path = generateRuleMd name rule;
          }) config.hdwlinux.ai.clients.rules
        );

        skillsDir = pkgs.linkFarm "augment-skills" (
          lib.mapAttrsToList (name: path: {
            inherit name path;
          }) config.hdwlinux.ai.clients.skills
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
        ) (lib.filterAttrs (n: _: n != "augment-context-engine") config.hdwlinux.ai.clients.mcpServers);

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
