{
  config.substrate.modules.programs.augment = {
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
        # Generate YAML frontmatter from all metadata keys
        metadataToFrontmatter =
          metadata: lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value: "${key}: ${value}") metadata);

        # Generate markdown with frontmatter from all metadata
        generateMd =
          name: item:
          let
            frontmatter = ''
              ---
              ${metadataToFrontmatter item.metadata}
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
              name: agent: "cp ${generateMd name agent} $out/${name}.md"
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
        ) config.hdwlinux.ai.agent.mcpServers;

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
