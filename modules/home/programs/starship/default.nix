{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.starship;
in
{
  options.hdwlinux.programs.starship = {
    enable = lib.hdwlinux.mkEnableOption "starship" true;
    extraSettings = lib.mkOption {
      description = "Options to pass to `programs.starship.settings`.";
      type = lib.types.attrs;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableBashIntegration = config.hdwlinux.programs.bash.enable;
      enableZshIntegration = config.hdwlinux.programs.zsh.enable;
      settings = {
        command_timeout = 5000;
        format = "$nix_shell$shell$username$hostname$directory\${custom.jj}$git_branch$git_commit$git_state$git_metrics$git_status$kubernetes$line_break$character";

        profiles = {
          transient = "$time $character";
        };

        character = {
          success_symbol = "[❯](${config.hdwlinux.theme.colors.withHashtag.base09})";
          error_symbol = "[❯](${config.hdwlinux.theme.colors.withHashtag.base08})";
        };

        directory = {
          style = config.hdwlinux.theme.colors.withHashtag.base0C;
          truncation_symbol = "…/";
          truncate_to_repo = true;
          truncation_length = 3;
        };

        fill.symbol = " ";

        git_branch = {
          disabled = true;
          style = config.hdwlinux.theme.colors.withHashtag.base04;
          symbol = "";
          format = "[$symbol$branch(:$remote_branch)]($style)";
        };

        git_commit.disabled = true;
        git_metrics.disabled = true;
        git_state.disabled = true;
        git_status = {
          disabled = true;
          style = config.hdwlinux.theme.colors.withHashtag.base04;
        };

        nix_shell = {
          symbol = "❄️ ";
          format = "[$symbol]($style)";
        };

        shell = {
          disabled = false;
          style = config.hdwlinux.theme.colors.withHashtag.base0C;
          bash_indicator = "";
          powershell_indicator = "";
          zsh_indicator = "";
        };

        time = {
          disabled = false;
          style = config.hdwlinux.theme.colors.withHashtag.base0D;
          format = "[$time]($style) ";
        };

        username = {
          show_always = false;
          style_user = config.hdwlinux.theme.colors.withHashtag.base05;
          format = "[$user]($style) ";
        };

        custom.jj = {
          ignore_timeout = true;
          description = "The current jj status";
          detect_folders = [ ".jj" ];
          command = ''
            jj log --revisions @ --no-graph --ignore-working-copy --color always --limit 1 --template '
              separate(" ",
                change_id.shortest(4),
                bookmarks,
                "|",
                concat(
                  if(conflict, "💥"),
                  if(divergent, "🚧"),
                  if(hidden, "👻"),
                  if(immutable, "🔒"),
                ),
                raw_escape_sequence("\x1b[2;34m") ++ if(empty, "(empty)"),
                raw_escape_sequence("\x1b[2;34m") ++ if(description.first_line().len() == 0,
                  "(no description set)",
                  if(description.first_line().substr(0, 29) == description.first_line(),
                    description.first_line(),
                    description.first_line().substr(0, 29) ++ "…",
                  )
                ) ++ raw_escape_sequence("\x1b[0m"),
              )
            '
          '';
        };
      } // cfg.extraSettings;
    };
  };
}
