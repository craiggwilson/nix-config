{
  config.substrate.modules.programs.starship = {
    tags = [ "programming" ];

    perUser =
      { config, pkgs, ... }:
      let
        colors = config.hdwlinux.theme.colors.hexWithHashtag;

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
            command = builtins.readFile ./starship-jj-command.txt;
          };
        };
      in
      {
        packages = [ pkgs.starship ];

        env.STARSHIP_CONFIG = "${config.homeDirectory}/.config/starship.toml";

        files.".config/starship.toml".source = (pkgs.formats.toml { }).generate "starship.toml" settings;

        hdwlinux.shell.zsh.initLines = [
          {
            prio = 430;
            text = ''
              if [[ $TERM != "dumb" ]]; then
                eval "$(${pkgs.starship}/bin/starship init zsh)"
              fi
            '';
          }
        ];
        hdwlinux.shell.bash.initLines = [
          {
            prio = 560;
            text = ''
              if [[ $TERM != "dumb" ]]; then
                eval "$(${pkgs.starship}/bin/starship init bash --print-full-init)"
              fi
            '';
          }
        ];
      };
  };
}
