{
  config.substrate.modules.programs.obsidian = {
    tags = [ "gui" ];

    homeManager =
      { config, pkgs, ... }:
      let
        colors = config.hdwlinux.theme.colors.withHashtag;
      in
      {
        programs.obsidian = {
          enable = true;
          cli.enable = true;

          vaults.kb.target = "Projects/kb";

          defaultSettings = {
            app = {
              "community-plugin-safe-mode" = false;
            };

            appearance = {
              theme = if config.hdwlinux.theme.dark then "obsidian" else "moonstone";
            };

            communityPlugins = [
              { pkg = pkgs.callPackage ./plugins/_excalidraw.nix { }; }
              { pkg = pkgs.callPackage ./plugins/_folder-notes.nix { }; }
              { pkg = pkgs.callPackage ./plugins/_file-ignore.nix { }; }
            ];

            cssSnippets = [
              {
                name = "hdwlinux-theme";
                text = ''
                  :root {
                    --color-base-00: ${colors.base00};
                    --color-base-01: ${colors.base01};
                    --color-base-02: ${colors.base02};
                    --color-base-03: ${colors.base03};
                    --color-base-04: ${colors.base04};
                    --color-base-05: ${colors.base05};
                    --color-base-06: ${colors.base06};
                    --color-base-07: ${colors.base07};
                    --color-base-08: ${colors.base08};
                    --color-base-09: ${colors.base09};
                    --color-base-0A: ${colors.base0A};
                    --color-base-0B: ${colors.base0B};
                    --color-base-0C: ${colors.base0C};
                    --color-base-0D: ${colors.base0D};
                    --color-base-0E: ${colors.base0E};
                    --color-base-0F: ${colors.base0F};

                    --background-primary: ${colors.base00};
                    --background-primary-alt: ${colors.base01};
                    --background-secondary: ${colors.base01};
                    --background-secondary-alt: ${colors.base02};
                    --background-modifier-border: ${colors.base02};
                    --background-modifier-form-field: ${colors.base01};
                    --background-modifier-form-field-highlighted: ${colors.base02};
                    --background-modifier-box-shadow: ${colors.base00};
                    --background-modifier-success: ${colors.base0B};
                    --background-modifier-error: ${colors.base08};
                    --background-modifier-error-rgb: 243, 139, 168;
                    --background-modifier-error-hover: ${colors.base08};

                    --text-normal: ${colors.base05};
                    --text-muted: ${colors.base04};
                    --text-faint: ${colors.base03};
                    --text-on-accent: ${colors.base00};
                    --text-error: ${colors.base08};
                    --text-warning: ${colors.base0A};
                    --text-success: ${colors.base0B};
                    --text-selection: ${colors.base02};
                    --text-accent: ${colors.base0D};
                    --text-accent-hover: ${colors.base0E};

                    --interactive-normal: ${colors.base01};
                    --interactive-hover: ${colors.base02};
                    --interactive-accent: ${colors.base0D};
                    --interactive-accent-hover: ${colors.base0E};
                    --interactive-success: ${colors.base0B};

                    --scrollbar-bg: ${colors.base01};
                    --scrollbar-thumb-bg: ${colors.base03};
                    --scrollbar-active-thumb-bg: ${colors.base04};
                  }
                '';
              }
            ];
          };
        };
      };
  };
}
