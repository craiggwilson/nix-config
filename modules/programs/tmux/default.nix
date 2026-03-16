{
  config.substrate.modules.programs.tmux = {
    tags = [ "programming" ];

    homeManager =
      {
        config,
        pkgs,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors.withHashtag;

        # Status bar colors
        themeColor = colors.base0D; # blue - main accent
        prefixColor = colors.base0A; # yellow - prefix accent (set to themeColor for no change)
        prefixBg = colors.base00; # base - prefix background (set to bg for no change)
        bg = colors.base00; # base - status bar background
        mid = colors.base02; # surface0 - mid-section background
        fg = colors.base04; # surface2 - foreground text

        themeScript = pkgs.writeShellScript "hdwlinux-theme.tmux" ''
          TC='${themeColor}'
          PC='${prefixColor}'
          BG='${bg}'
          PBG='${prefixBg}'
          MID='${mid}'
          FG='${fg}'

          rarrow=$'\ue0b8'
          larrow=$'\ue0ba'
          session_icon=$'\uf530'
          user_icon=$'\uf007'

          # CTC/CBG are tmux format strings evaluated at render time
          CTC="#{?client_prefix,$PC,$TC}"
          CBG="#{?client_prefix,$PBG,$BG}"

          tmux set-option -gq status-interval 1
          tmux set-option -gq status on

          # status-bg does not support format strings; use static bg
          tmux set-option -gq status-bg "$BG"

          # Left: accent segment -> mid segment -> bg
          tmux set-option -gq status-left-length 150
          tmux set-option -gq status-left \
            "#[fg=$CBG,bg=$CTC,bold] $user_icon $(whoami)@#h #[fg=$CTC,bg=$MID,nobold]$rarrow#[fg=$CTC,bg=$MID] $session_icon #S #[fg=$MID,bg=$CBG]$rarrow"

          # Right: bg -> mid segment -> accent segment
          tmux set-option -gq status-right-length 150
          tmux set-option -gq status-right \
            "#[fg=$MID,bg=$CBG]$larrow#[fg=$CTC,bg=$MID] %T #[fg=$CTC,bg=$MID]$larrow#[fg=$CBG,bg=$CTC] %F "

          # Window status - both accent and background change on prefix
          tmux set-option -gq window-status-format \
            "#[fg=$CBG,bg=$MID]$rarrow#[fg=$CTC,bg=$MID] #I:#W#F #[fg=$MID,bg=$CBG]$rarrow"
          tmux set-option -gq window-status-current-format \
            "#[fg=$CBG,bg=$CTC]$rarrow#[fg=$CBG,bg=$CTC,bold] #I:#W#F #[fg=$CTC,bg=$CBG,nobold]$rarrow"
          tmux set-option -gq window-status-style          "fg=$TC,bg=$BG,none"
          tmux set-option -gq window-status-last-style     "fg=$TC,bg=$BG,bold"
          tmux set-option -gq window-status-activity-style "fg=$TC,bg=$BG,bold"
          tmux set-option -gq window-status-separator      ""

          # Pane borders
          tmux set-option -gq pane-border-style        "fg=$MID,bg=default"
          tmux set-option -gq pane-active-border-style "fg=$CTC,bg=default"

          # Pane number indicator (format strings not supported here, use static colors)
          tmux set-option -gq display-panes-colour        "$MID"
          tmux set-option -gq display-panes-active-colour "$TC"

          # Clock
          tmux set-option -gq clock-mode-colour "$TC"
          tmux set-option -gq clock-mode-style  24

          # Messages
          tmux set-option -gq message-style         "fg=$CTC,bg=$BG"
          tmux set-option -gq message-command-style "fg=$CTC,bg=$BG"

          # Copy mode
          tmux set-option -gq mode-style "bg=$CTC,fg=$FG"
        '';
      in
      {
        programs.tmux = {
          enable = true;
          shell = "${pkgs.zsh}/bin/zsh";
          terminal = "tmux-256color";
          historyLimit = 10000;
          escapeTime = 0;
          keyMode = "vi";
          mouse = true;
          prefix = "M-`";
          baseIndex = 1;
          focusEvents = true;
          disableConfirmationPrompt = true;

          plugins = [
            pkgs.tmuxPlugins.tmux-fzf
          ];

          extraConfig = ''
            TMUX_FZF_LAUNCH_KEY="f"
            set -g status-position top
            run-shell ${themeScript}

            bind r source-file ${config.xdg.configHome}/tmux/tmux.conf

            # Windows
            bind c new-window -c "#{pane_current_path}"
            bind k unlink-window -k

            bind -r PageUp swap-window -d -t -1
            bind -r PageDown swap-window -d -t +1

            # Pane 
            set -g pane-base-index 1
            set -g renumber-windows on

            bind -r Left select-pane -L
            bind -r Right select-pane -R
            bind -r Up select-pane -U
            bind -r Down select-pane -D

            bind -r M-Left swap-pane -s '{left-of}'
            bind -r M-Right swap-pane -s '{right-of}'
            bind -r M-Up swap-pane -s '{up-of}'
            bind -r M-Down swap-pane -s '{down-of}'

            bind -r M-S-Left resize-pane -L 5
            bind -r M-S-Right resize-pane -R 5
            bind -r M-S-Up resize-pane -U 5
            bind -r M-S-Down resize-pane -D 5

            bind \\ split-window -h -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"

          '';
        };
      };
  };
}
