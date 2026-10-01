{
  # Zsh syntax-highlighting styles from the active palette (theming adapter).
  config.substrate.settings.theming.apps.zsh = {
    enabled = { config, ... }: true;

    apply.homeManager =
      { theme, ... }:
      let
        colors = theme.colors.hexWithHashtag;
      in
      {
        programs.zsh.syntaxHighlighting.styles = {
          comment = "fg=${colors.base04}";
          alias = "fg=${colors.base0B}";
          suffix-alias = "fg=${colors.base0B}";
          global-alias = "fg=${colors.base0B}";
          function = "fg=${colors.base0B}";
          command = "fg=${colors.base0B}";
          precommand = "fg=${colors.base0B},italic";
          autodirectory = "fg=${colors.base09},italic";
          single-hyphen-option = "fg=${colors.base09}";
          double-hyphen-option = "fg=${colors.base09}";
          back-quoted-argument = "fg=${colors.base0E}";
          builtin = "fg=${colors.base0B}";
          reserved-word = "fg=${colors.base0B}";
          hashed-command = "fg=${colors.base0B}";
          commandseparator = "fg=${colors.base08}";
          command-substitution-delimiter = "fg=${colors.base05}";
          command-substitution-delimiter-unquoted = "fg=${colors.base05}";
          process-substitution-delimiter = "fg=${colors.base05}";
          back-quoted-argument-delimiter = "fg=${colors.base08}";
          back-double-quoted-argument = "fg=${colors.base08}";
          back-dollar-quoted-argument = "fg=${colors.base08}";
          command-substitution-quoted = "fg=${colors.base0A}";
          command-substitution-delimiter-quoted = "fg=${colors.base0A}";
          single-quoted-argument = "fg=${colors.base0A}";
          single-quoted-argument-unclosed = "fg=${colors.base08}";
          double-quoted-argument = "fg=${colors.base0A}";
          double-quoted-argument-unclosed = "fg=${colors.base08}";
          rc-quote = "fg=${colors.base0A}";
          dollar-quoted-argument = "fg=${colors.base05}";
          dollar-quoted-argument-unclosed = "fg=${colors.base08}";
          dollar-double-quoted-argument = "fg=${colors.base05}";
          assign = "fg=${colors.base05}";
          named-fd = "fg=${colors.base05}";
          numeric-fd = "fg=${colors.base05}";
          unknown-token = "fg=${colors.base08}";
          path = "fg=${colors.base05},underline";
          path_pathseparator = "fg=${colors.base08},underline";
          path_prefix = "fg=${colors.base05},underline";
          path_prefix_pathseparator = "fg=${colors.base08},underline";
          globbing = "fg=${colors.base05}";
          history-expansion = "fg=${colors.base0E}";
          back-quoted-argument-unclosed = "fg=${colors.base08}";
          redirection = "fg=${colors.base05}";
          arg0 = "fg=${colors.base05}";
          default = "fg=${colors.base05}";
          cursor = "fg=${colors.base05}";
        };
      };
  };
}
