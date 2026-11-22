{
  config.substrate.modules.programs.vscodium = {
    tags = [
      "desktop"
      "profile:programming"
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
        shared = import ./_lib.nix {
          inherit
            config
            host
            lib
            pkgs
            ;
        };
        inherit (shared) mkCanonicalSettings mkProfile;
        inherit (shared.layers)
          goLayer
          javaLayer
          nixLayer
          pythonLayer
          rustLayer
          terraformLayer
          ;

        # Profiles: each is a composition of layers.
        profiles = {
          default = mkProfile [ ];
          nix = mkProfile [ nixLayer ];
          rust = mkProfile [ rustLayer ];
          go = mkProfile [ goLayer ];
          python = mkProfile [ pythonLayer ];
          java = mkProfile [ javaLayer ];
          terraform = mkProfile [ terraformLayer ];
        };
      in
      lib.mkMerge (
        [
          {
            programs.vscodium = {
              enable = true;
              profiles = lib.mapAttrs (_: profile: {
                inherit (profile) enableMcpIntegration extensions keybindings;
              }) profiles;
            };

            home.packages = [
              (pkgs.writeShellApplication {
                name = "code";
                runtimeInputs = [ pkgs.vscodium ];
                text = builtins.readFile ./code.sh;
              })
              (pkgs.writeShellApplication {
                name = "vscode-diff-settings";
                runtimeInputs = [
                  pkgs.coreutils
                  pkgs.gnused
                  pkgs.ripgrep
                ];
                # SC2001 suggests ${diff//^/  }, which anchors at the start of the
                # whole string and so indents only the first line.
                excludeShellChecks = [ "SC2001" ];
                text = builtins.readFile ./vscode-diff-settings.sh;
              })
            ];

            # Only codium.desktop is actually installed — the `code` wrapper
            # above has no desktop file, so "code.desktop" IDs in mimeapps
            # resolve to nothing and gio silently falls back to whatever
            # desktop file happens to register the type.
            xdg.mimeApps.defaultApplications = lib.genAttrs [
              "application/json"
              "application/x-php"
              "application/yaml"
              "text/css"
              "text/markdown"
              "text/plain"
              "text/x-c++hdr"
              "text/x-c++src"
              "text/x-chdr"
              "text/x-csrc"
              "text/x-diff"
              "text/x-dsrc"
              "text/x-java"
              "text/x-nix"
              "text/x-pascal"
              "text/x-perl"
              "text/x-python"
              "text/x-sql"
            ] (_: "codium.desktop");
          }
        ]
        ++ lib.mapAttrsToList (name: profile: mkCanonicalSettings name profile._settings) profiles
      );
  };
}
