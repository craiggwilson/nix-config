{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.vscode;
in
{
  options.hdwlinux.features.vscode = with types; {
    enable = mkEnableOpt ["gui" "programming"] config.hdwlinux.features.tags;
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
      ] ++ lib.optionals config.hdwlinux.theme.enable [
        (let
          themeFile = pkgs.writeTextFile {
            name = "vscode-hdwlinux-theme.json";
            text = (import ./template.nix) config.hdwlinux.theme.colors;
          };
        in pkgs.runCommandLocal "hdwlinux-vscode" {
            vscodeExtUniqueId = "hdwlinux.hdwlinux";
            vscodeExtPublisher = "hdwlinux";
            version = "0.0.0";
          } ''
            mkdir -p "$out/share/vscode/extensions/$vscodeExtUniqueId/themes"
            ln -s ${./package.json} "$out/share/vscode/extensions/$vscodeExtUniqueId/package.json"
            ln -s ${themeFile} "$out/share/vscode/extensions/$vscodeExtUniqueId/themes/hdwlinux.json"
          ''
        )
      ];

      userSettings = {
        "explorer.confirmDragAndDrop" = false;
        "editor.inlineSuggest.enabled" = true;
        "editor.fontFamily" = "FiraCode Nerd Font Mono";
        "editor.fontLigatures" = true;
        "explorer.confirmDelete" = false;
        "lldb.suppressUpdateNotifications" = true;
        "protoc" = {
            "options" = [
                "--proto_path=\${workspaceRoot}/proto"
            ];
        };
        "rust-analyzer.inlayHints.parameterHints.enable" = false;
        "rust-analyzer.inlayHints.typeHints.enable" = false;
        "rust-analyzer.inlayHints.closingBraceHints.enable" = false;
        "terminal.integrated.fontFamily" = "FiraCode Nerd Font Mono";
        "window.menuBarVisibility" = "toggle";
        "window.titleBarStyle" = "custom";
        "workbench.startupEditor" = "none";
        "workbench.colorTheme" = "hdwlinux";
      };
    };

    xdg.mimeApps.defaultApplications."text/plain" = "code.desktop";
  };
}
