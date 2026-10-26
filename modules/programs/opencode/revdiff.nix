{
  config.substrate.modules.programs.opencode.revdiff = {
    tags = [
      "profile:ai"
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # OpenCode v2 auto-discovers the CLI plugin in plugins/revdiff/; no
        # opencode.json registration is needed. The launcher shells out to the
        # revdiff binary, which must be on PATH.
        revdiff = pkgs.hdwlinux.revdiff;
        pluginDir = "${revdiff}/share/revdiff/opencode/plugins/revdiff";
        pluginFiles = [
          "tui.ts"
          "claims.ts"
          "launcher.ts"
          "package.json"
        ];
        scriptFiles = [
          "agentdeck-window.sh"
          "launch-revdiff.sh"
        ];

        colors = config.hdwlinux.theme.colors.hexWithHashtag;

        # Theme the TUI from the active hdwlinux palette, mapped the same way
        # as the herdr theme. Colors live in the [color options] section;
        # behavior keys would go headerless (default section) above it.
        revdiffConfig = ''
          [color options]
          color-accent = ${colors.base0E}
          color-border = ${colors.base03}
          color-normal = ${colors.base05}
          color-muted = ${colors.base04}
          color-selected-fg = ${colors.base00}
          color-selected-bg = ${colors.base0E}
          color-annotation = ${colors.base0A}
          color-cursor-fg = ${colors.base0A}
          color-add-fg = ${colors.base0B}
          color-add-bg = ${colors.base01}
          color-remove-fg = ${colors.base08}
          color-remove-bg = ${colors.base01}
          color-modify-fg = ${colors.base0A}
          color-modify-bg = ${colors.base01}
          color-tree-bg = ${colors.base00}
          color-diff-bg = ${colors.base00}
          color-status-fg = ${colors.base01}
          color-status-bg = ${colors.base0E}
          color-search-fg = ${colors.base00}
          color-search-bg = ${colors.base0D}
        '';
      in
      {
        home.packages = [ revdiff ];

        xdg.configFile = lib.mkMerge [
          (lib.listToAttrs (
            map (
              file: lib.nameValuePair "opencode/plugins/revdiff/${file}" { source = "${pluginDir}/${file}"; }
            ) pluginFiles
          ))
          (lib.listToAttrs (
            map (
              file:
              lib.nameValuePair "opencode/plugins/revdiff/scripts/${file}" {
                source = "${pluginDir}/scripts/${file}";
              }
            ) scriptFiles
          ))
          { "revdiff/config".text = revdiffConfig; }
        ];
      };
  };
}
