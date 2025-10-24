{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.augment;

  augmentMcpServers = lib.mapAttrs (name: server: {
    # type = server.type; This isn't used by Augment
    command = server.command;
    args = server.args;
  }) config.hdwlinux.mcpServers;

in
{
  options.hdwlinux.programs.augment = {
    enable = config.lib.hdwlinux.mkEnableOption "augment" [
      "programming"
      "work"
    ];
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."augment/mcp-servers.json".text = builtins.toJSON {
      mcpServers = augmentMcpServers;
    };

    programs.vscode.profiles.default = {
      extensions = [
        # Doesn't exist yet.
        # pkgs.vscode-extensions.augment.vscode-augment
      ];
      userSettings = lib.mkIf config.hdwlinux.programs.vscode.enable {
        "github.copilot.enable" = {
          "*" = false;
        };
      };
    };
  };
}
