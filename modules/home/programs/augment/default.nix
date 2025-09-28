{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.augment;
in
{
  options.hdwlinux.programs.augment = {
    enable = config.lib.hdwlinux.mkEnableOption "augment" [
      "programming"
      "work"
    ];
  };

  config = {
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
