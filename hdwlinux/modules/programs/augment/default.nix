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
      {
        home.packages = [
          (pkgs.writeShellScriptBin "auggie" ''
            ${pkgs.hdwlinux.auggie}/bin/auggie --mcp-config ~/.ai/agent/mcp-servers.json "$@"
          '')
        ];

        home.file = {
          ".augment/agents".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.ai/agent/agents";
          ".augment/commands".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.ai/agent/commands";
          ".augment/rules".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.ai/agent/rules";
          ".augment/skills".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.ai/agent/skills";
          #".augment/settings.json".source = ./settings.json;
        };

        programs.vscode.profiles.default.userSettings = lib.mkIf config.programs.vscode.enable {
          "github.copilot.enable" = {
            "*" = false;
          };
        };
      };
  };
}
