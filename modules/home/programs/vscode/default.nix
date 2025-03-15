{
  config,
  lib,
  pkgs,
  flake,
  host,
  ...
}:

let
  cfg = config.hdwlinux.programs.vscode;
in
{
  options.hdwlinux.programs.vscode = {
    enable = config.lib.hdwlinux.mkEnableOption "vscode" [
      "gui"
      "programming"
    ];
    theme = lib.mkOption {
      description = "The theme name to use";
      type = lib.types.str;
      default = "hdwlinux";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      mutableExtensionsDir = true;

      extensions = with pkgs.vscode-extensions; [
        golang.go
        rust-lang.rust-analyzer
        tamasfe.even-better-toml
        jnoortheen.nix-ide
        zxh404.vscode-proto3
        (
          let
            themeFile = pkgs.writeTextFile {
              name = "vscode-hdwlinux-theme.json";
              text = (import ./template.nix) config.hdwlinux.theme.colors;
            };
          in
          pkgs.runCommandLocal "hdwlinux-vscode"
            {
              vscodeExtUniqueId = "hdwlinux.hdwlinux";
              vscodeExtPublisher = "hdwlinux";
              version = "0.0.0";
            }
            ''
              mkdir -p "$out/share/vscode/extensions/$vscodeExtUniqueId/themes"
              ln -s ${./package.json} "$out/share/vscode/extensions/$vscodeExtUniqueId/package.json"
              ln -s ${themeFile} "$out/share/vscode/extensions/$vscodeExtUniqueId/themes/hdwlinux.json"
            ''
        )
      ];

      userSettings = lib.mkMerge [
        {
          "explorer.confirmDragAndDrop" = false;
          "editor.inlineSuggest.enabled" = true;
          "editor.fontFamily" = "FiraCode Nerd Font Mono";
          "editor.fontLigatures" = true;
          "explorer.confirmDelete" = false;
          "lldb.suppressUpdateNotifications" = true;
          "nix.enableLanguageServer" = true;
          "nix.formatterPath" = [
            "nix"
            "fmt"
            "--"
            "--"
          ];
          "nix.hiddenLanguageServerErrors" = [
            "textDocument/definition"
            "textDocument/formatting"
          ];
          "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
          "nix.serverSettings" = {
            "nixd" = {
              "nixpkgs" = {
                "expr" = ''import (builtins.getFlake "${flake}").inputs.nixpkgs { }'';
              };

              "formatting" = {
                "command" = [
                  "nix"
                  "fmt"
                  "--"
                  "--"
                ];
              };
              "options" = {
                "enable" = true;
                "nixos" = {
                  "expr" = ''(builtins.getFlake "${flake}").nixosConfigurations.${host}.options'';
                };
                "home-manager" = {
                  "expr" =
                    ''(builtins.getFlake "${flake}").homeConfigurations."${config.hdwlinux.user.name}@${host}".options'';
                };
              };
              "diagnostic" = {
                "suppress" = [
                ];
              };
            };
          };
          "protoc" = {
            "options" = [ "--proto_path=\${workspaceRoot}/proto" ];
          };
          "rust-analyzer.inlayHints.parameterHints.enable" = false;
          "rust-analyzer.inlayHints.typeHints.enable" = false;
          "rust-analyzer.inlayHints.closingBraceHints.enable" = false;
          "update.mode" = "none";
          "window.menuBarVisibility" = "toggle";
          "window.titleBarStyle" = "custom";
          "workbench.startupEditor" = "none";
          "workbench.colorTheme" = "${cfg.theme}";

          "[nix]" = {
            "editor.formatOnSave" = true;
          };

          "[rust]" = {
            "editor.formatOnSave" = true;
            "editor.inlayHints.enabled" = "off";
            "files.insertFinalNewline" = true;
            "files.trimFinalNewlines" = true;
          };
        }
        (lib.mkIf config.hdwlinux.programs.jujutsu.enable {
          "git.autofetch" = false;
          "git.enabled" = false;
          "git.path" = null;
        })
      ];
    };

    xdg.mimeApps.defaultApplications."text/plain" = "code.desktop";
  };
}
