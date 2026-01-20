{
  config.substrate.modules.programs.augment = {
    tags = [
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
        # Transform tagged union to augment's expected format (stdio servers only)
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
        ) config.hdwlinux.ai.mcpServers;

      in
      {
        home.packages = [
          (pkgs.writeShellScriptBin "auggie" ''
            ${pkgs.hdwlinux.auggie}/bin/auggie --mcp-config ~/.augment/mcp-servers.json "$@"
          '')
        ];

        home.file = {
          ".augment/mcp-servers.json".text = builtins.toJSON {
            inherit mcpServers;
          };
          # ".augment/settings.json".source =
          #   config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/programs/augment/settings.json";
        }
        // (lib.mapAttrs' (
          n: v: lib.nameValuePair ".augment/agents/${n}.md" { text = v; }
        ) config.hdwlinux.ai.agents)
        // (lib.mapAttrs' (
          n: v: lib.nameValuePair ".augment/commands/${n}.md" { text = v; }
        ) config.hdwlinux.ai.commands)
        // (lib.mapAttrs' (
          n: v: lib.nameValuePair ".augment/rules/${n}.md" { text = v; }
        ) config.hdwlinux.ai.rules);

        programs.vscode.profiles.default.userSettings = lib.mkIf config.programs.vscode.enable {
          "github.copilot.enable" = {
            "*" = false;
          };
        };
      };
  };
}
