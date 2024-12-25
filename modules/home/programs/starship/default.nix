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
        format = "$nix_shell$shell$username$hostname$directory$git_branch$git_commit$git_state$git_metrics$git_status$kubernetes$line_break$character";

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
          style = config.hdwlinux.theme.colors.withHashtag.base04;
          symbol = "";
          format = "[$symbol$branch(:$remote_branch)]($style)";
        };

        git_status.style = config.hdwlinux.theme.colors.withHashtag.base04;

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
      } // cfg.extraSettings;
    };
  };
}
