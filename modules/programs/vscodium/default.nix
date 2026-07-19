{
  config.substrate.modules.programs.vscode = {
    tags = [
      "gui"
      "programming"
    ];

    homeManager =
      {
        config,
        hasTag,
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

        themeFile = pkgs.writeTextFile {
          name = "vscode-hdwlinux-theme.json";
          text = (import ./_template.nix) themeColors;
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

        # ---------------------------------------------------------------------------
        # Layers: each layer has { extensions, settings }.
        # Profiles are composed by merging layers together.
        # ---------------------------------------------------------------------------

        baseLayer = {
          extensions = [
            themeExtension
            annotativeExtension
            pkgs.vscode-extensions.visualjj.visualjj
          ];
          settings = {
            "editor.fontFamily" = "FiraCode Nerd Font Mono";
            "editor.fontLigatures" = true;
            "editor.inlineSuggest.enabled" = true;
            "excalidraw.theme" = "auto";
            "explorer.confirmDelete" = false;
            "explorer.confirmDragAndDrop" = false;
            "extensions.autoCheckUpdates" = false;
            "github.copilot.enable"."*" = false;
            "terminal.integrated.defaultProfile.linux" = "zsh";
            "update.mode" = "none";
            "window.menuBarVisibility" = "toggle";
            "window.titleBarStyle" = "custom";
            "workbench.colorTheme" = "hdwlinux";
            "workbench.editor.pinnedTabsOnSeparateRow" = true;
            "workbench.startupEditor" = "none";
          };
        };

        annotativeExtension = pkgs.stdenv.mkDerivation {
          pname = "vscode-extension-bryan-shea-annotative";
          version = "3.1.0";

          src = pkgs.fetchurl {
            url = "https://github.com/bryan-shea/Annotative/releases/download/v3.1.0/annotative-3.1.0.vsix";
            sha256 = "sha256-6lKvdHPJxctj+me8P62CcChuKAe9Lzi6YGjw21s9DTk=";
            name = "bryan-shea.annotative-3.1.0.vsix";
          };

          vscodeExtUniqueId = "bryan-shea.annotative";
          vscodeExtPublisher = "bryan-shea";

          phases = [
            "unpackPhase"
            "installPhase"
          ];

          unpackPhase = ''
            mkdir -p extract
            cd extract
            unzip -q "$src"
            cd ..
          '';

          installPhase = ''
            mkdir -p "$out/share/vscode/extensions/$vscodeExtUniqueId"
            cp -r extract/extension/* "$out/share/vscode/extensions/$vscodeExtUniqueId/"
          '';

          buildInputs = [ pkgs.unzip ];
        };

        kdlExtension = pkgs.stdenv.mkDerivation {
          pname = "vscode-extension-v1hz-kdl";
          version = "2.1.3";

          src = pkgs.fetchurl {
            url = "https://open-vsx.org/api/v1hz/kdl/2.1.3/file/v1hz.kdl-2.1.3.vsix";
            sha256 = "sha256-i5J4hXU3cOnFiPS+LZ0fIwwQo7hV0dueF0cPXUv25z0=";
            name = "v1hz-kdl-2.1.3.vsix";
          };

          vscodeExtUniqueId = "v1hz.kdl";
          vscodeExtPublisher = "v1hz";

          phases = [
            "unpackPhase"
            "installPhase"
          ];

          unpackPhase = ''
            mkdir -p extract
            cd extract
            unzip -q "$src"
            cd ..
          '';

          installPhase = ''
            mkdir -p "$out/share/vscode/extensions/$vscodeExtUniqueId"
            cp -r extract/extension/* "$out/share/vscode/extensions/$vscodeExtUniqueId/"
          '';

          buildInputs = [ pkgs.unzip ];
        };

        nixLayer = {
          extensions = with pkgs.vscode-extensions; [
            jnoortheen.nix-ide
            kdlExtension
          ];
          settings = {
            "[nix]"."editor.formatOnSave" = true;
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
            "nix.serverSettings"."nixd" = {
              "diagnostic"."suppress" = [ ];
              "formatting"."command" = [
                "nix"
                "fmt"
                "--"
                "--"
              ];
              "nixpkgs"."expr" = ''import (builtins.getFlake "${flake}").inputs.nixpkgs { }'';
              "options" = {
                "enable" = true;
                "home-manager"."expr" =
                  ''(builtins.getFlake "${flake}").homeConfigurations."${config.hdwlinux.user.name}@${host}".options'';
                "nixos"."expr" = ''(builtins.getFlake "${flake}").nixosConfigurations.${host}.options'';
              };
            };
          };
        };

        rustLayer = {
          extensions = with pkgs.vscode-extensions; [
            rust-lang.rust-analyzer
            tamasfe.even-better-toml
          ];
          settings = {
            "[rust]" = {
              "editor.formatOnSave" = true;
              "editor.inlayHints.enabled" = "off";
              "files.insertFinalNewline" = true;
              "files.trimFinalNewlines" = true;
            };
            "lldb.suppressUpdateNotifications" = true;
            "rust-analyzer.inlayHints.closingBraceHints.enable" = false;
            "rust-analyzer.inlayHints.parameterHints.enable" = false;
            "rust-analyzer.inlayHints.typeHints.enable" = false;
          };
        };

        goLayer = {
          extensions = with pkgs.vscode-extensions; [
            golang.go
          ];
          settings = {
            "go.lintOnSave" = "package";
            "go.lintTool" = "golangci-lint";
            "go.vetOnSave" = "off";
          };
        };

        typescriptLayer = {
          extensions = with pkgs.vscode-extensions; [
            biomejs.biome
          ];
          settings = {
            "[javascript][javascriptreact][typescript][typescriptreact][json][jsonc][css][graphql]" = {
              "editor.codeActionsOnSave" = {
                "quickfix.biome" = "explicit";
                "source.organizeImports.biome" = "explicit";
              };
              "editor.defaultFormatter" = "biomejs.biome";
              "editor.formatOnSave" = true;
            };
            "biome.suggestInstallingGlobally" = false;
          };
        };

        pythonLayer = {
          extensions = with pkgs.vscode-extensions; [
            ms-python.python
            charliermarsh.ruff
          ];
          settings = { };
        };

        javaLayer = {
          extensions = with pkgs.vscode-extensions; [
            redhat.java
          ];
          settings = { };
        };

        bazelLayer = {
          extensions = with pkgs.vscode-extensions; [
            bazelbuild.vscode-bazel
          ];
          settings = {
            "protoc"."options" = [ "--proto_path=\${workspaceRoot}/proto" ];
            "bazel.buildifierExecutable" = lib.getExe' pkgs.bazel-buildtools "buildifier";
          };
        };

        # ---------------------------------------------------------------------------
        # Helpers
        # ---------------------------------------------------------------------------

        # Merge a list of layers into combined { extensions, settings }.
        mergeLayers =
          layers:
          lib.foldl'
            (acc: layer: {
              extensions = acc.extensions ++ layer.extensions;
              settings = acc.settings // layer.settings;
            })
            {
              extensions = [ ];
              settings = { };
            }
            layers;

        # Generate canonical settings file and merge activation script.
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

        # Keybindings shared across all profiles.
        sharedKeybindings = [
          {
            key = "ctrl+alt+shift+p";
            command = "workbench.profiles.actions.switchProfile";
          }
          {
            key = "alt+left";
            command = "workbench.action.navigateBack";
            when = "canNavigateBack";
          }
          {
            key = "alt+right";
            command = "workbench.action.navigateForward";
            when = "canNavigateForward";
          }
        ];

        # Build a VSCodium profile from a list of layers.
        mkProfile =
          layers:
          let
            merged = mergeLayers ([ baseLayer ] ++ layers);
          in
          {
            enableMcpIntegration = true;
            inherit (merged) extensions;
            keybindings = sharedKeybindings;
            _settings = merged.settings;
          };

        # Profiles: each is a composition of layers.
        profiles = {
          default = mkProfile [ ];
          nix = mkProfile [ nixLayer ];
          rust = mkProfile [ rustLayer ];
          go = mkProfile [ goLayer ];
          typescript = mkProfile [ typescriptLayer ];
          python = mkProfile [ pythonLayer ];
          java = mkProfile [ javaLayer ];
        };

        mmsProfile = mkProfile [
          javaLayer
          goLayer
          bazelLayer
        ];

      in
      lib.mkMerge (
        [
          {
            programs.vscodium = {
              enable = true;

              profiles =
                lib.mapAttrs (_: p: {
                  inherit (p) enableMcpIntegration extensions keybindings;
                }) profiles
                // lib.optionalAttrs (hasTag "users:craig:work") {
                  mms = {
                    inherit (mmsProfile) enableMcpIntegration extensions keybindings;
                  };
                };
            };

            home.packages = [
              (pkgs.writeShellScriptBin "code" (builtins.readFile ./code.sh))
              (pkgs.writeShellScriptBin "vscode-diff-settings" (builtins.readFile ./vscode-diff-settings.sh))
            ];

            xdg.mimeApps.defaultApplications."text/plain" = "code.desktop";
          }
          (lib.mkIf (hasTag "users:craig:work") (mkCanonicalSettings "mms" mmsProfile._settings))
        ]
        ++ lib.mapAttrsToList (name: p: mkCanonicalSettings name p._settings) profiles
      );
  };
}
