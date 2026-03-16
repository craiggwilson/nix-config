{
  config.substrate.modules.programs.claude-code = {
    tags = [
      "ai:agent"
      "programming"
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
        # Resolve an alias name to a Claude Code model string.
        # If the alias points to the anthropic provider, use the model name directly.
        # Otherwise, infer the Claude Code alias from the model name pattern.
        resolveModel =
          aliasName:
          let
            alias = config.hdwlinux.ai.agent.models.aliases.${aliasName};
          in
          if alias.provider == "anthropic" then
            alias.model
          else if lib.hasInfix "haiku" alias.model then
            "haiku"
          else if lib.hasInfix "opus" alias.model then
            "opus"
          else
            "sonnet";

        # Generate a Claude Code subagent markdown file from an agent definition.
        # Frontmatter: name, description, model. Body is the agent's prompt content.
        generateAgentMd =
          name: agent:
          let
            model = resolveModel agent.model;
            frontmatterLines = [
              "name: ${name}"
              "description: ${agent.description}"
              "model: ${model}"
            ];
            frontmatter = "---\n${lib.concatStringsSep "\n" frontmatterLines}\n---\n\n";
            body = builtins.readFile agent.prompt;
          in
          pkgs.writeText "${name}.md" (frontmatter + body);

        # Generate a Claude Code rule file for auto-loaded rules.
        # Uses description frontmatter so Claude knows when to load it.
        generateRuleMd =
          name: rule:
          let
            frontmatter = "---\ndescription: ${rule.description}\n---\n\n";
            body = builtins.readFile rule.prompt;
          in
          pkgs.writeText "${name}.md" (frontmatter + body);

        # Partition rules into always-loaded and auto-loaded.
        alwaysRules = lib.filterAttrs (_: r: r.loadMode == "always") config.hdwlinux.ai.agent.rules;
        autoRules = lib.filterAttrs (_: r: r.loadMode == "auto") config.hdwlinux.ai.agent.rules;

        # Generate CLAUDE.md content: imports each always-loaded rule from the nix store.
        claudeMdContent =
          let
            imports = lib.mapAttrsToList (
              _: rule: "@${builtins.unsafeDiscardStringContext (toString rule.prompt)}"
            ) alwaysRules;
          in
          lib.concatStringsSep "\n" imports + "\n";

        # Build a derivation containing symlinks to all agent markdown files.
        agentsDir = pkgs.linkFarm "claude-code-agents" (
          lib.mapAttrsToList (name: agent: {
            name = "${name}.md";
            path = generateAgentMd name agent;
          }) config.hdwlinux.ai.agent.agents
        );

        # Build a derivation containing symlinks to all auto-rule markdown files.
        rulesDir = pkgs.linkFarm "claude-code-rules" (
          lib.mapAttrsToList (name: rule: {
            name = "${name}.md";
            path = generateRuleMd name rule;
          }) autoRules
        );

        # Build a derivation containing symlinks to all skills (same structure as OpenCode).
        skillsDir = pkgs.linkFarm "claude-code-skills" (
          lib.mapAttrsToList (name: path: {
            inherit name;
            path = path;
          }) config.hdwlinux.ai.agent.skills
        );

        # Translate hdwlinux.ai.agent.tools into Claude Code permission lists.
        # Handles bash, read, write, edit, and external_directory.
        # Simple "allow" tools and catch-all "*" patterns are skipped (allow is the default),
        # except for external_directory "allow" patterns which are explicitly emitted into
        # the allow list for Read, Write, and Edit so those paths are accessible outside
        # the working directory. Deny rules still take priority over these allow entries.
        toolsToClaudePermissions =
          tools:
          let
            toolPrefix = {
              bash = "Bash";
              edit = "Edit";
              read = "Read";
              write = "Write";
            };

            collectEntries =
              perm: toolName: toolValue:
              let
                prefix = toolPrefix.${toolName} or null;
              in
              if prefix == null then
                [ ]
              else if builtins.isString toolValue then
                lib.optional (toolValue == perm) "${prefix}(*)"
              else
                lib.concatLists (
                  lib.mapAttrsToList (
                    pattern: p: lib.optional (p == perm && pattern != "*") "${prefix}(${pattern})"
                  ) toolValue
                );

            # external_directory allow patterns are expanded into explicit allow entries
            # for Read, Write, and Edit so Claude Code permits access to those paths.
            externalDirAllows =
              let
                extDir = tools.external_directory or { };
                allowPatterns =
                  if builtins.isString extDir then
                    [ ]
                  else
                    lib.mapAttrsToList (pattern: p: pattern) (
                      lib.filterAttrs (pattern: p: p == "allow" && pattern != "*") extDir
                    );
              in
              lib.concatLists (
                map (pattern: [
                  "Read(${pattern})"
                  "Write(${pattern})"
                  "Edit(${pattern})"
                ]) allowPatterns
              );

            allDeny = lib.concatLists (
              lib.mapAttrsToList (name: value: collectEntries "deny" name value) tools
            );
            allAsk = lib.concatLists (lib.mapAttrsToList (name: value: collectEntries "ask" name value) tools);
            allAllow = externalDirAllows;
          in
          {
            deny = allDeny;
            ask = allAsk;
            allow = allAllow;
          };

        derivedPermissions = toolsToClaudePermissions config.hdwlinux.ai.agent.tools;

        # Transform MCP servers to Claude Code's --mcp-config JSON format.
        mcpConfig = {
          mcpServers = lib.mapAttrs (
            _: server:
            if server ? stdio then
              {
                type = "stdio";
                command = server.stdio.command;
                args = server.stdio.args;
              }
            else if server ? http then
              {
                type = "http";
                url = server.http.url;
                headers = server.http.headers;
              }
            else
              throw "Unknown MCP server type"
          ) config.hdwlinux.ai.agent.mcpServers;
        };

        # Claude Code settings.json with permissions.
        settingsJson = {
          "$schema" = "https://json.schemastore.org/claude-code-settings.json";
          env = {
            CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
          };
          permissions = {
            allow = derivedPermissions.allow;
            deny = derivedPermissions.deny;
            ask = derivedPermissions.ask;
            defaultMode = "dontAsk";
            disableBypassPermissionsMode = "disable";
          };
          sandbox = {
            enabled = false;
          };
          autoUpdatesChannel = "latest";
          includeGitInstructions = false;
          respectGitignore = true;
          # Use tmux panes for agent teams so each teammate gets its own terminal
          teammateMode = "tmux";
        };

        # Wrapper script that passes --mcp-config so MCP servers are available
        # without touching ~/.claude.json (which Claude manages itself for session state).
        claudeWrapper = pkgs.writeShellScriptBin "claude" ''
          exec ${pkgs.claude-code}/bin/claude \
            --mcp-config "${config.home.homeDirectory}/.claude/mcp-servers.json" \
            "$@"
        '';

      in
      {
        home.packages = [ claudeWrapper ];

        home.file = {
          ".claude/CLAUDE.md".text = claudeMdContent;
          ".claude/agents".source = agentsDir;
          ".claude/rules".source = rulesDir;
          ".claude/skills".source = skillsDir;
          ".claude/mcp-servers.json".text = builtins.toJSON mcpConfig;
          ".claude/settings.json".text = builtins.toJSON settingsJson;
        };
      };
  };
}
