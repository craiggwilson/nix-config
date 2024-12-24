{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.zed-editor;
in
{
  options.hdwlinux.programs.zed-editor = {
    enable = config.lib.hdwlinux.mkEnableOption "zed-editor" [
      "programming"
      "gui"
    ];
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      extensions = [
        "catppuccin"
        "golangci-lint"
        "gosum"
        "html"
        "nix"
      ];
      userSettings = {
        telemetry = {
          metrics = false;
          diagnostics = false;
        };
        theme = {
          mode = "dark";
          light = "Catppuccin Frappé";
          dark = "Catppuccin Mocha";
        };
      };
    };
  };
}
