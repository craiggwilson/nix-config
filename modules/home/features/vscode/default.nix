{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.vscode;
in
{
  options.hdwlinux.features.vscode = with types; {
    enable = mkBoolOpt false "Whether or not to enable vscode.";
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      mutableExtensionsDir = true;

      extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
        golang.go
        tamasfe.even-better-toml
        vadimcn.vscode-lldb
        zxh404.vscode-proto3
      ];

      userSettings = {
        "rust-analyzer.inlayHints.parameterHints.enable" = false;
        "rust-analyzer.inlayHints.typeHints.enable" = false;
        "explorer.confirmDelete" = false;
        "editor.inlineSuggest.enabled" = true;
        "editor.fontFamily" = "FiraCode Nerd Font Mono";
        "editor.fontLigatures" = true;
        "rust-analyzer.inlayHints.closingBraceHints.enable" = false;
        "lldb.suppressUpdateNotifications" = true;
        "protoc" = {
            "options" = [
                "--proto_path=\${workspaceRoot}/proto"
            ];
        };
        "explorer.confirmDragAndDrop" = false;
        "terminal.integrated.fontFamily" = "FiraCode Nerd Font Mono";
        "window.menuBarVisibility" = "toggle";
        "window.titleBarStyle" = "custom";
        "workbench.startupEditor" = "none";
      };
    };

    hdwlinux.theme.targets.vscode.enable = true;

    xdg.mimeApps.defaultApplications."text/plain" = "code.desktop";
  };
}
