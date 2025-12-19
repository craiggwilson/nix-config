{
  config.substrate.modules.programs.starship = {
    tags = [ "programming" ];

    homeManager =
      { config, ... }:
      let
        colors = config.hdwlinux.theme.colors.withHashtag;
      in
      {
        programs.starship = {
          enable = true;
          enableBashIntegration = config.programs.bash.enable;
          enableZshIntegration = config.programs.zsh.enable;
          settings = {
            command_timeout = 5000;
            format = "$nix_shell$shell$username$hostname$directory\${custom.jj}$kubernetes$line_break$character";

            profiles = {
              transient = "$time$character";
            };

            character = {
              success_symbol = "[❯](${colors.base09})";
              error_symbol = "[❯](${colors.base08})";
            };

            directory = {
              style = colors.base0C;
              truncation_symbol = "…/";
              truncate_to_repo = true;
              truncation_length = 3;
            };

            fill.symbol = " ";

            nix_shell = {
              symbol = "❄️ ";
              format = "[$symbol]($style)";
            };

            shell = {
              disabled = false;
              style = colors.base0C;
              bash_indicator = "";
              powershell_indicator = "";
              zsh_indicator = "";
            };

            time = {
              disabled = false;
              style = colors.base0D;
              format = "[$time]($style) ";
            };

            username = {
              show_always = false;
              style_user = colors.base05;
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
          };
        };
      };
  };
}

