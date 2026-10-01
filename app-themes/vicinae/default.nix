{
  # Vicinae theme rendered to a file (theming adapter): vicinae reads
  # ~/.config/vicinae/themes/, so a theme switch applies without a rebuild.
  config.substrate.settings.theming.apps.vicinae = {
    enabled = { config, ... }: config.programs ? vicinae && config.programs.vicinae.enable;

    templates =
      { theme, pkgs }:
      {
        # vicinae >= 0.15 reads TOML themes.
        "vicinae/themes/hdwlinux.toml" = {
          content = (pkgs.formats.toml { }).generate "vicinae-hdwlinux-theme.toml" (
            import ./_theme.nix theme.colors
          );
          dest = "$HOME/.config/vicinae/themes/hdwlinux.toml";
        };
      };
  };
}
