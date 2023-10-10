{ lib, pkgs, config, ... }:
{
  hdwlinux.packages.vscode = {
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      golang.go
      tamasfe.even-better-toml
      vadimcn.vscode-lldb
      zxh404.vscode-proto3
    ];

    settings = {
      "rust-analyzer.inlayHints.parameterHints.enable" = false;
      "rust-analyzer.inlayHints.typeHints.enable" = false;
      "explorer.confirmDelete" = false;
      "editor.inlineSuggest.enabled" = true;
      "rust-analyzer.inlayHints.closingBraceHints.enable" = false;
      "lldb.suppressUpdateNotifications" = true;
      "protoc" = {
          "options" = [
              "--proto_path=\${workspaceRoot}/proto"
          ];
      };
      "explorer.confirmDragAndDrop" = false;
      "terminal.integrated.fontFamily" = "DroidSansMono";
      "window.menuBarVisibility" = "toggle";
      "window.titleBarStyle" = "custom";
      "workbench.startupEditor" = "none";
      "workbench.colorTheme" = "Nord Deep";
    };
  };
}
