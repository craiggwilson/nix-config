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
        augmentMcpServers = lib.mapAttrs (name: server: {
          command = server.command;
          args = server.args;
        }) config.hdwlinux.ai.mcpServers;
      in
      {
        home.packages = [
          (pkgs.writeShellScriptBin "auggie" ''
            ${pkgs.hdwlinux.auggie}/bin/auggie --mcp-config ~/.augment/mcp-servers.json "$@"
          '')
        ];

        home.file = {
          ".augment/mcp-servers.json".text = builtins.toJSON {
            mcpServers = augmentMcpServers;
          };
        }
        // (lib.mapAttrs' (
          n: v: lib.nameValuePair ".augment/agents/${n}.md" { text = v; }
        ) config.hdwlinux.ai.agents);

        programs.vscode.profiles.default.userSettings = lib.mkIf config.programs.vscode.enable {
          "github.copilot.enable" = {
            "*" = false;
          };
        };
      };
  };
}
