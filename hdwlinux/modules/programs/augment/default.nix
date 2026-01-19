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
        mcpServers = lib.mapAttrs (name: server: {
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
