{
  config.substrate.modules.programs.obsidian = {
    tags = [ "gui" ];

    homeManager =
      {
        config,
        pkgs,
        wrap,
        ...
      }:
      let
        themeColors = config.hdwlinux.theme.colors;

        # Keep the plugin's Python lookup local to the wrapper instead of
        # baking it into a custom join.
        obsidianWithPython = wrap.package {
          package = pkgs.obsidian;
          runtimeInputs = [ pkgs.python3 ];
        };

        themePackage = pkgs.runCommandLocal "hdwlinux-obsidian-theme" { } ''
          mkdir -p "$out"
          cp ${pkgs.writeText "manifest.json" (builtins.toJSON {
            name = "hdwlinux";
            version = "0.0.0";
            minAppVersion = "1.0.0";
            author = "hdwlinux";
          })} "$out/manifest.json"
          cp ${pkgs.writeText "theme.css" ((import ./_template.nix) themeColors)} "$out/theme.css"
        '';
      in
      {
        programs.obsidian = {
          enable = true;
          package = obsidianWithPython;
          cli.enable = true;

          vaults.kb.target = "Projects/kb";

          defaultSettings = {
            app = {
              "community-plugin-safe-mode" = false;
            };

            appearance = {
              # "obsidian" = dark mode, "moonstone" = light mode
              theme = if config.hdwlinux.theme.dark then "obsidian" else "moonstone";
            };

            communityPlugins = [
              { pkg = pkgs.callPackage ./plugins/_excalidraw.nix { }; }
              { pkg = pkgs.callPackage ./plugins/_file-ignore.nix { }; }
              { pkg = pkgs.callPackage ./plugins/_folder-notes.nix { }; }
              { pkg = pkgs.callPackage ./plugins/_terminal.nix { }; }
            ];

            themes = [
              { pkg = themePackage; }
            ];
          };
        };
      };
  };
}
