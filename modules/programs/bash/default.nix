{
  config.substrate.modules.programs.bash = {
    tags = [ "programming" ];

    # Owns ~/.bashrc, ~/.profile, ~/.bash_profile. Snippet pats here: the
    # contributor blocks land after the completion block, in HM's order
    # (ghostty, fzf, yazi, direnv, starship, zoxide); aliases and completion
    # are rendered by this module before all snippets.
    # hdwlinux.shell options are declared by the zsh module (same tag).
    perUser =
      { config, lib, pkgs, ... }:
      let
        cfg = config.hdwlinux.shell;

        snippetBlocks = map (s: lib.trim s.text) cfg.bash.initLines;

        aliasLines = lib.mapAttrsToList (
          name: value: "alias -- ${name}=" + (if lib.hasInfix " " value then lib.escapeShellArg value else value)
        ) cfg.aliases;

        hmSessionVars = "/etc/profiles/per-user/${config.hdwlinux.user.name}/etc/profile.d/hm-session-vars.sh";

        # The literal ends with a newline; drop it so every snippet junction
        # is the standard single blank line (the leading "\n\n" is HM's own
        # prefix and stays).
        bashrcCore = lib.removeSuffix "\n" ''


          # Commands that should be applied only for interactive shells.
          [[ $- == *i* ]] || return

          HISTCONTROL=erasedups:ignoredups:ignorespace
          HISTFILE="${config.homeDirectory}/.local/share/bash/history"
          HISTFILESIZE=10000
          HISTSIZE=10000
          mkdir -p "$(dirname "$HISTFILE")"

          shopt -s histappend
          shopt -s extglob
          shopt -s globstar
          shopt -s checkjobs

          ${lib.concatStringsSep "\n" aliasLines}

          if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
            . "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh"
          fi
        ''
          + lib.concatMapStrings (b: "\n\n" + b) snippetBlocks
          + "\n\n";
      in
      {
        config = {
          files.".bashrc".text = bashrcCore;

          # Transitional home-manager session-vars source; deleted with HM.
          # Carries services.ssh-agent's SSH_AUTH_SOCK default (unit stays
          # home-manager-side) so login shells keep working unchanged.
          files.".profile".text = ''
            . "${hmSessionVars}"

            if [ -z "$SSH_AUTH_SOCK" -o -z "$SSH_CONNECTION" ]; then
              export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
            fi
          '';

          files.".bash_profile".text = ''
            # include .profile if it exists
            [[ -f ~/.profile ]] && . ~/.profile

            # include .bashrc if it exists
            [[ -f ~/.bashrc ]] && . ~/.bashrc
          '';
        };
      };
  };
}
