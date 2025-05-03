{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.zsh;
in
{
  options.hdwlinux.programs.zsh = {
    enable = lib.hdwlinux.mkEnableOption "zsh" true;
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableVteIntegration = true;
      autosuggestion.enable = true;
      history.size = 10000;
      history.ignoreAllDups = true;
      history.path = "$HOME/.zsh_history";
      history.ignorePatterns = [
        "cd *"
        "cp *"
        "exit"
        "ls *"
        "mv *"
        "pkill *"
        "rm *"
      ];
      initContent = ''
        bindkey "^[[1;5C"    forward-word
        bindkey "^[[1;5D"    backward-word
        bindkey  "^[[1;6C"  end-of-line
        bindkey  "^[[1;6D"   beginning-of-line

        bindkey  "^[[F"      end-of-line
        bindkey  "^[[H"      beginning-of-line

        source ${./transient-prompt.zsh}
      '';
      syntaxHighlighting = {
        enable = true;
        styles = lib.mkIf config.hdwlinux.theme.enable {
          comment = "fg=${config.hdwlinux.theme.colors.withHashtag.base04}";
          alias = "fg=${config.hdwlinux.theme.colors.withHashtag.base0B}";
          suffix-alias = "fg=${config.hdwlinux.theme.colors.withHashtag.base0B}";
          global-alias = "fg=${config.hdwlinux.theme.colors.withHashtag.base0B}";
          function = "fg=${config.hdwlinux.theme.colors.withHashtag.base0B}";
          command = "fg=${config.hdwlinux.theme.colors.withHashtag.base0B}";
          precommand = "fg=${config.hdwlinux.theme.colors.withHashtag.base0B},italic";
          autodirectory = "fg=${config.hdwlinux.theme.colors.withHashtag.base09},italic";
          single-hyphen-option = "fg=${config.hdwlinux.theme.colors.withHashtag.base09}";
          double-hyphen-option = "fg=${config.hdwlinux.theme.colors.withHashtag.base09}";
          back-quoted-argument = "fg=${config.hdwlinux.theme.colors.withHashtag.base0E}";
          builtin = "fg=${config.hdwlinux.theme.colors.withHashtag.base0B}";
          reserved-word = "fg=${config.hdwlinux.theme.colors.withHashtag.base0B}";
          hashed-command = "fg=${config.hdwlinux.theme.colors.withHashtag.base0B}";
          commandseparator = "fg=${config.hdwlinux.theme.colors.withHashtag.base08}";
          command-substitution-delimiter = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          command-substitution-delimiter-unquoted = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          process-substitution-delimiter = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          back-quoted-argument-delimiter = "fg=${config.hdwlinux.theme.colors.withHashtag.base08}";
          back-double-quoted-argument = "fg=${config.hdwlinux.theme.colors.withHashtag.base08}";
          back-dollar-quoted-argument = "fg=${config.hdwlinux.theme.colors.withHashtag.base08}";
          command-substitution-quoted = "fg=${config.hdwlinux.theme.colors.withHashtag.base0A}";
          command-substitution-delimiter-quoted = "fg=${config.hdwlinux.theme.colors.withHashtag.base0A}";
          single-quoted-argument = "fg=${config.hdwlinux.theme.colors.withHashtag.base0A}";
          single-quoted-argument-unclosed = "fg=${config.hdwlinux.theme.colors.withHashtag.base08}";
          double-quoted-argument = "fg=${config.hdwlinux.theme.colors.withHashtag.base0A}";
          double-quoted-argument-unclosed = "fg=${config.hdwlinux.theme.colors.withHashtag.base08}";
          rc-quote = "fg=${config.hdwlinux.theme.colors.withHashtag.base0A}";
          dollar-quoted-argument = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          dollar-quoted-argument-unclosed = "fg=${config.hdwlinux.theme.colors.withHashtag.base08}";
          dollar-double-quoted-argument = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          assign = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          named-fd = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          numeric-fd = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          unknown-token = "fg=${config.hdwlinux.theme.colors.withHashtag.base08}";
          path = "fg=${config.hdwlinux.theme.colors.withHashtag.base05},underline";
          path_pathseparator = "fg=${config.hdwlinux.theme.colors.withHashtag.base08},underline";
          path_prefix = "fg=${config.hdwlinux.theme.colors.withHashtag.base05},underline";
          path_prefix_pathseparator = "fg=${config.hdwlinux.theme.colors.withHashtag.base08},underline";
          globbing = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          history-expansion = "fg=${config.hdwlinux.theme.colors.withHashtag.base0E}";
          back-quoted-argument-unclosed = "fg=${config.hdwlinux.theme.colors.withHashtag.base08}";
          redirection = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          arg0 = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          default = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
          cursor = "fg=${config.hdwlinux.theme.colors.withHashtag.base05}";
        };
      };
    };
  };
}
