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
        jsonFormat = pkgs.formats.json { };
        userDir = "${config.xdg.configHome}/VSCodium/User";

        # Transform tagged union to VS Code's expected format
        vscodeMcpServers = lib.mapAttrs (
          name: server:
          if server ? stdio then
            {
              command = server.stdio.command;
              args = server.stdio.args;
            }
          else if server ? http then
            {
              url = server.http.url;
              headers = server.http.headers;
            }
          else
            throw "Unknown MCP server type for ${name}"
        ) config.hdwlinux.ai.agent.mcpServers;

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

        # Canonical settings (Nix is the source of truth)
        canonicalSettings = {
          "[javascript][javascriptreact][typescript][typescriptreact][json][jsonc][css][graphql]" = {
            "editor.codeActionsOnSave" = {
              "quickfix.biome" = "explicit";
              "source.organizeImports.biome" = "explicit";
            };
            "editor.defaultFormatter" = "biomejs.biome";
            "editor.formatOnSave" = true;
          };
          "[nix]" = {
            "editor.formatOnSave" = true;
          };
          "[rust]" = {
            "editor.formatOnSave" = true;
            "editor.inlayHints.enabled" = "off";
            "files.insertFinalNewline" = true;
            "files.trimFinalNewlines" = true;
          };
          "biome.suggestInstallingGlobally" = false;
          "editor.fontFamily" = "FiraCode Nerd Font Mono";
          "editor.fontLigatures" = true;
          "editor.inlineSuggest.enabled" = true;
          "excalidraw.theme" = "auto";
          "explorer.confirmDelete" = false;
          "explorer.confirmDragAndDrop" = false;
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
              "diagnostic" = {
                "suppress" = [ ];
              };
              "formatting" = {
                "command" = [
                  "nix"
                  "fmt"
                  "--"
                  "--"
                ];
              };
              "nixpkgs" = lib.mkIf (flake != null) {
                "expr" = ''import (builtins.getFlake "${flake}").inputs.nixpkgs { }'';
              };
              "options" = lib.mkIf (flake != null) {
                "enable" = true;
                "home-manager" = {
                  "expr" =
                    ''(builtins.getFlake "${flake}").homeConfigurations."${config.hdwlinux.user.name}@${host}".options'';
                };
                "nixos" = {
                  "expr" = ''(builtins.getFlake "${flake}").nixosConfigurations.${host}.options'';
                };
              };
            };
          };
          "protoc" = {
            "options" = [ "--proto_path=\${workspaceRoot}/proto" ];
          };
          "rust-analyzer.inlayHints.closingBraceHints.enable" = false;
          "rust-analyzer.inlayHints.parameterHints.enable" = false;
          "rust-analyzer.inlayHints.typeHints.enable" = false;
          "terminal.integrated.defaultProfile.linux" = "zsh";
          "update.mode" = "none";
          "window.menuBarVisibility" = "toggle";
          "window.titleBarStyle" = "custom";
          "workbench.colorTheme" = "hdwlinux";
          "workbench.editor.pinnedTabsOnSeparateRow" = true;
          "workbench.startupEditor" = "none";
        };

        # Helper: generates canonical settings file and merge activation script
        mkCanonicalSettings =
          profileName: settings:
          let
            settingsDir = if profileName == "default" then userDir else "${userDir}/profiles/${profileName}";
          in
          {
            home.file."${settingsDir}/settings.canonical.json".source =
              jsonFormat.generate "vscode-settings-${profileName}" settings;

            home.activation."vscodeSettings-${profileName}" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              settings_dir="${settingsDir}"
              canonical="$settings_dir/settings.canonical.json"
              target="$settings_dir/settings.json"

              if [ -f "$target" ] && [ ! -L "$target" ]; then
                if run ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$target" "$canonical" > "$target.new"; then
                  run mv "$target.new" "$target"
                  verboseEcho "Merged VS Code settings for profile '${profileName}'"
                else
                  errorEcho "Failed to merge VS Code settings for profile '${profileName}'"
                fi
              else
                run rm -f "$target"
                if run cp "$canonical" "$target" && run chmod 644 "$target"; then
                  verboseEcho "Initialized VS Code settings for profile '${profileName}'"
                else
                  errorEcho "Failed to initialize VS Code settings for profile '${profileName}'"
                fi
              fi
            '';
          };

      in
      lib.mkMerge [
        {
          programs.vscode = {
            enable = true;
            package = pkgs.vscodium;
            mutableExtensionsDir = true;

            profiles.default = {
              enableExtensionUpdateCheck = false;
              enableUpdateCheck = false;
              extensions = [
                themeExtension
              ]
              ++ (with pkgs.vscode-extensions; [
                biomejs.biome
                golang.go
                jnoortheen.nix-ide
                rust-lang.rust-analyzer
                tamasfe.even-better-toml
                visualjj.visualjj
              ]);
              userMcp.servers = vscodeMcpServers;
            };
          };

          xdg.mimeApps.defaultApplications."text/plain" = "code.desktop";
        }
        (mkCanonicalSettings "default" canonicalSettings)
      ];
  };
}
