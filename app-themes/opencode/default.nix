{
  # OpenCode theme rendered to a file (theming adapter): opencode reads
  # ~/.config/opencode/themes/<name>.json, so a theme switch applies to the
  # next instance without a rebuild.
  config.substrate.settings.theming.apps.opencode = {
    enabled = { config, ... }: config.programs ? opencode && config.programs.opencode.enable;

    templates =
      { theme, ... }:
      {
        "opencode/themes/hdwlinux.json" = {
          content = builtins.toJSON (
            { "$schema" = "https://opencode.ai/theme.json"; } // import ./_theme.nix theme.colors
          );
          dest = "$HOME/.config/opencode/themes/hdwlinux.json";
        };
      };
  };
}
