{
  config.substrate.modules.programs.zsh = {
    tags = [ "programming" ];

    nixos =
      { pkgs, ... }:
      {
        programs.zsh.enable = true;
        users.defaultUserShell = pkgs.zsh;
      };

    # Owns ~/.zshenv + ~/.config/zsh/{.zshenv,.zprofile,.zshrc}. Also the
    # single owner of the shared `hdwlinux.shell` registry (initLines +
    # aliases) that the bash module and every integration contributor feed;
    # same tag, so the declarations and consumers always co-occur.
    #
    # Snippet pats: <200 lands after compinit/autosuggest, 200-399 after the
    # history block, >=400 after initContent. Contributors keep their
    # home-manager blocks until their config-file waves; the
    # enableZshIntegration = config.programs.zsh.enable lines they share go
    # inert automatically now that HM's zsh module is off.
    perUser =
      { config, lib, pkgs, ... }:
      let
        colors = config.hdwlinux.theme.colors.hexWithHashtag;
        cfg = config.hdwlinux.shell;

        snippetType = lib.types.submodule {
          options = {
            prio = lib.mkOption {
              type = lib.types.int;
              default = 100;
              description = "Order among init snippets (lower comes first).";
            };
            text = lib.mkOption {
              type = lib.types.lines;
              description = "Init snippet body (rendered as its own block).";
            };
          };
        };

        sortSnippets = lib.sort (
          a:
          b:
          a.prio < b.prio || (a.prio == b.prio && a.text < b.text)
        );
        # Blocks joined by exactly one blank line; each is trimmed so
        # contributors can't drift the vertical whitespace.
        joinBlocks = blocks: builtins.concatStringsSep "\n\n" (map lib.trim blocks);
        snippetBlocks =
          lo: hi: snips:
          map (s: lib.trim s.text) (builtins.filter (s: s.prio >= lo && s.prio < hi) snips);

        # Transitional while home-manager still delivers sessionVariables:
        # source its vars script through the stable per-user profile link so
        # not-yet-migrated env (EDITOR, GTK_*, NIRI_*, ...) survives shells.
        # Delete these three strings in the HM-removal wave.
        hmSessionVars = "/etc/profiles/per-user/${config.hdwlinux.user.name}/etc/profile.d/hm-session-vars.sh";
        sessionVarsBlock = ''
          # Environment variables
          . "${hmSessionVars}"

          # Only source this once
          if [[ -z "''${__HM_ZSH_SESS_VARS_SOURCED-}" ]]; then
            export __HM_ZSH_SESS_VARS_SOURCED=1
          fi
        '';
        # services.ssh-agent's shell contribution (still home-manager-side;
        # its systemd unit keeps working without HM touching the rcs).
        sshAgentBlock = ''
          if [ -z "$SSH_AUTH_SOCK" -o -z "$SSH_CONNECTION" ]; then
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
          fi
        '';

        aliasLines = lib.mapAttrsToList (
          name: value: "alias -- ${name}=" + (if lib.hasInfix " " value then lib.escapeShellArg value else value)
        ) cfg.aliases;

        syntaxHighlightStyles = {
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

        zshrc = joinBlocks (
          [
            ''
              typeset -U path cdpath fpath manpath
              for profile in ''${(z)NIX_PROFILES}; do
                fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
              done
            ''
            "HELPDIR=\"${pkgs.zsh}/share/zsh/$ZSH_VERSION/help\""
            # Home-manager emitted a double blank line between this block and
            # the first integration snippet; restored by replaceStrings below.
            ''
              autoload -U compinit && compinit
              source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
              ZSH_AUTOSUGGEST_STRATEGY=(history)
            ''
          ]
          ++ (snippetBlocks 0 200 cfg.zsh.initLines)
          ++ [
            # History options live in .zshrc and after other init, matching
            # home-manager's placement (see hm#177).
            ''
              # History options should be set in .zshrc and after oh-my-zsh sourcing.
              # See https://github.com/nix-community/home-manager/issues/177.
              HISTSIZE="10000"
              SAVEHIST="10000"
              HISTORY_IGNORE='(cd *|cp *|exit|ls *|mv *|pkill *|rm *)'
              HISTFILE="${config.homeDirectory}/.local/state/zsh_history"
              mkdir -p "$(dirname "$HISTFILE")"
            ''
          ]
          ++ (snippetBlocks 200 400 cfg.zsh.initLines)
          ++ [
            ''
              # Set shell options
              set_opts=(
                HIST_FCNTL_LOCK HIST_IGNORE_ALL_DUPS HIST_IGNORE_DUPS HIST_IGNORE_SPACE
                SHARE_HISTORY NO_APPEND_HISTORY NO_EXTENDED_HISTORY NO_HIST_EXPIRE_DUPS_FIRST
                NO_HIST_FIND_NO_DUPS NO_HIST_SAVE_NO_DUPS
              )
              for opt in "''${set_opts[@]}"; do
                setopt "$opt"
              done
              unset opt set_opts
            ''
            ''
              bindkey "^[[1;5C"    forward-word
              bindkey "^[[1;5D"    backward-word
              bindkey  "^[[1;6C"  end-of-line
              bindkey  "^[[1;6D"   beginning-of-line

              bindkey  "^[[F"      end-of-line
              bindkey  "^[[H"      beginning-of-line

              source ${./transient-prompt.zsh}
            ''
          ]
          ++ (snippetBlocks 400 1000 cfg.zsh.initLines)
          ++ [
            ". ${pkgs.vte}/etc/profile.d/vte.sh"
            # Aliases flow straight into syntax-highlighting (no blank line),
            # so they are one block.
            (
              lib.concatStringsSep "\n" aliasLines
              + "\n"
              + ''
                source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
                ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
              ''
              + lib.concatStrings (
                lib.mapAttrsToList (k: v: "ZSH_HIGHLIGHT_STYLES[${k}]=${lib.escapeShellArg v}\n") syntaxHighlightStyles
              )
            )
          ]
        );

        # Double blank line after the autosuggestion block, byte-matching
        # home-manager's init sectioning.
        zshrcText = lib.replaceStrings [ "ZSH_AUTOSUGGEST_STRATEGY=(history)\n\n" ] [ "ZSH_AUTOSUGGEST_STRATEGY=(history)\n\n\n" ] zshrc;
      in
      {
        options.hdwlinux.shell = {
          aliases = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Shell aliases emitted into zsh and bash interactive init.";
          };
          zsh.initLines = lib.mkOption {
            type = lib.types.listOf snippetType;
            default = [ ];
            apply = sortSnippets;
            description = "zsh init snippets, rendered in priority order.";
          };
          bash.initLines = lib.mkOption {
            type = lib.types.listOf snippetType;
            default = [ ];
            apply = sortSnippets;
            description = "bash init snippets, rendered in priority order.";
          };
        };

        config = {
          files.".zshenv".text = "source ${config.homeDirectory}/.config/zsh/.zshenv\n";

          files.".config/zsh/.zshenv".text = ''
            if [[ ! -o login ]]; then
              ${sessionVarsBlock}
            fi

            export ZDOTDIR="${config.homeDirectory}/.config/zsh"

            if [[ ! -o login ]]; then
              ${sshAgentBlock}
            fi
          '';

          files.".config/zsh/.zprofile".text = ''
            ${sessionVarsBlock}

            ${sshAgentBlock}
          '';

          files.".config/zsh/.zshrc".source = pkgs.writeText "zshrc" (zshrcText + "\n\n");
        };
      };
  };
}
