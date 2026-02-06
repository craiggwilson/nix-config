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
      {
        home.packages = [
          (pkgs.writeShellScriptBin "auggie" ''
            ${pkgs.hdwlinux.auggie}/bin/auggie --mcp-config ~/.ai/agent/mcp-servers.json "$@"
          '')
        ];

        # Symlink ~/.augment -> ~/.ai/agent for Augment Code compatibility
        home.file.".augment".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.ai/agent";

        programs.vscode.profiles.default.userSettings = lib.mkIf config.programs.vscode.enable {
          "github.copilot.enable" = {
            "*" = false;
          };
        };
      };
  };
}
