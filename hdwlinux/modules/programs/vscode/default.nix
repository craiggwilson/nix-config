{
  config.substrate.modules.programs.vscode = {
    tags = [
      "gui"
      "programming"
    ];

    homeManager =
      {
        config,
        host,
        pkgs,
        lib,
        ...
      }:
      let
        flake = config.hdwlinux.flake;
        themeColors = config.hdwlinux.theme.colors;

        vscodeMcpServers = lib.mapAttrs (name: server: {
          type = server.type;
          command = server.command;
          args = server.args;
        }) config.hdwlinux.mcpServers;

        themeFile = pkgs.writeTextFile {
          name = "vscode-hdwlinux-theme.json";
          text = (import ./_template.nix) themeColors.withHashtag;
        };
        themeExtension =
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
            '';
      in
      {
        programs.vscode = {
          enable = true;
          package = pkgs.vscodium;
          mutableExtensionsDir = true;

          profiles.default = {
            extensions = with pkgs.vscode-extensions; [
              golang.go
              rust-lang.rust-analyzer
              tamasfe.even-better-toml
              jnoortheen.nix-ide
              visualjj.visualjj
              themeExtension
            ];

            userSettings = lib.mkMerge [
              {
                "explorer.confirmDragAndDrop" = false;
                "editor.inlineSuggest.enabled" = true;
                "editor.fontFamily" = "FiraCode Nerd Font Mono";
                "editor.fontLigatures" = true;
                "explorer.confirmDelete" = false;
                "go.lintOnSave" = "package";
                "go.lintTool" = "golangci-lint";
                "go.vetOnSave" = "off";
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
                      "suppress" = [ ];
                    };
                  };
                };
                "protoc" = {
                  "options" = [ "--proto_path=\${workspaceRoot}/proto" ];
                };
                "rust-analyzer.inlayHints.parameterHints.enable" = false;
                "rust-analyzer.inlayHints.typeHints.enable" = false;
                "rust-analyzer.inlayHints.closingBraceHints.enable" = false;
                "terminal.integrated.defaultProfile.linux" = "zsh";
                "update.mode" = "none";
                "window.menuBarVisibility" = "toggle";
                "window.titleBarStyle" = "custom";
                "workbench.colorTheme" = "hdwlinux";
                "workbench.editor.pinnedTabsOnSeparateRow" = true;
                "workbench.startupEditor" = "none";
                "[nix]" = {
                  "editor.formatOnSave" = true;
                };
                "[rust]" = {
                  "editor.formatOnSave" = true;
                  "editor.inlayHints.enabled" = "off";
                  "files.insertFinalNewline" = true;
                  "files.trimFinalNewlines" = true;
                };
                "mcp.servers" = vscodeMcpServers;
              }
            ];
          };
        };

        xdg.mimeApps.defaultApplications."text/plain" = "code.desktop";
      };
  };
}
