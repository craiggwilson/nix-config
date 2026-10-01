{
  # Helix theme from the active palette (theming adapter).
  # Helix theme rendered to a file (theming adapter): helix reads
  # ~/.config/helix/themes/<name>.toml at startup, so a theme switch applies to
  # the next editor instance without a rebuild.
  config.substrate.settings.theming.apps.helix = {
    enabled = { config, ... }: config.programs ? helix && config.programs.helix.enable;

    templates =
      { theme, pkgs }:
      {
        "helix/themes/hdwlinux.toml" = {
          content = (pkgs.formats.toml { }).generate "hdwlinux.toml" (import ./_theme.nix theme.colors);
          dest = "$HOME/.config/helix/themes/hdwlinux.toml";
        };
      };
  };
}
