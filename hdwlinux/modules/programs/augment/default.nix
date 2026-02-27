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
            partsWithoutProvider =
              if builtins.length parts > 0 && builtins.elem (builtins.head parts) knownProviders then
                builtins.tail parts
              else
                parts;
            firstNumIdx =
              lib.lists.findFirstIndex isNumeric (builtins.length partsWithoutProvider)
                partsWithoutProvider;
          in
          if firstNumIdx == 0 || firstNumIdx >= builtins.length partsWithoutProvider then
            throw "Invalid model slug format: ${slug} (expected format: [provider-]family-version)"
          else
            let
              family = builtins.elemAt partsWithoutProvider (firstNumIdx - 1);
              versionParts = lib.drop firstNumIdx partsWithoutProvider;
              version = lib.concatStringsSep "." versionParts;
            in
            "${family}${version}";

        resolveAlias =
          aliasName:
          let
            alias = config.hdwlinux.ai.agent.models.aliases.${aliasName};
          in
          toAuggieSlug alias.model;

        extraMetaToFrontmatter =
          extraMeta:
          let
            augmentMeta = extraMeta.augment or { };
          in
          lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value: "${key}: ${value}") augmentMeta);

        formatTools = tools: lib.concatStringsSep ", " (lib.attrNames tools);

        generateAgentMd =
          name: agent:
          let
            formalFields = [
              "name: ${name}"
              "description: ${agent.description}"
              "model: ${resolveAlias agent.model}"
              "tools: ${formatTools agent.tools}"
            ];
            augmentMeta = agent.extraMeta.augment or { };
            extraFields = lib.mapAttrsToList (key: value: "${key}: ${value}") augmentMeta;
            allFields = formalFields ++ extraFields;
            frontmatter = ''
              ---
              ${lib.concatStringsSep "\n" allFields}
              ---

            '';
            content = builtins.readFile agent.prompt;
          in
          pkgs.writeText "${name}.md" (frontmatter + content);

        generateMd =
          name: item:
          let
            descriptionField = "description: ${item.description}";
            extraFields = extraMetaToFrontmatter item.extraMeta;
            allFields = if extraFields == "" then descriptionField else "${descriptionField}\n${extraFields}";
            frontmatter = ''
              ---
              ${allFields}
              ---

            '';
            content = builtins.readFile item.prompt;
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
            path = generateMd name command;
          }) config.hdwlinux.ai.agent.commands
        );

        rulesDir = pkgs.linkFarm "augment-rules" (
          lib.mapAttrsToList (name: rule: {
            name = "${name}.md";
            path = generateMd name rule;
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

        programs.vscode.profiles.default.userSettings = lib.mkIf config.programs.vscode.enable {
          "github.copilot.enable" = {
            "*" = false;
          };
        };
      };
  };
}
