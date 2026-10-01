{
  # Zellij theme generated from the active palette (theming adapter):
  # zellij lists ~/.config/zellij/themes/*.kdl in its theme picker, so a
  # switch applies to the next session without a rebuild.
  config.substrate.settings.theming.apps.zellij = {
    enabled = { config, ... }: config.programs ? zellij && config.programs.zellij.enable;

    templates =
      { theme, ... }:
      {
        "zellij/themes/hdwlinux.kdl" = {
          content = import ./_theme.nix theme.colors;
          dest = "$HOME/.config/zellij/themes/hdwlinux.kdl";
        };
      };
  };
}
