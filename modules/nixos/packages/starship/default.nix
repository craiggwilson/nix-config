{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.starship;
in
{
  options.hdwlinux.packages.starship = with types; {
    enable = mkBoolOpt false "Whether or not to enable starship.";
    settings = mkOpt attrs { } (mdDoc "Options to pass directly to `programs.starship.settings`.");
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.starship = {
      enable = true;
      enableBashIntegration = mkAliasDefinitions options.hdwlinux.packages.bash.enable;
      settings = cfg.settings // {
        command_timeout = 5000;
        format = "$shell$username$hostname$directory$git_branch$git_commit$git_state$git_metrics$git_status$kubernetes$line_break$character";

        character = {
          success_symbol = "[❯](#ff9400)";
          error_symbol = "[❯](#ff4b00)";
        };

        directory = {
          style = "cyan";
          truncation_symbol = "…/";
          truncate_to_repo = true;
          truncation_length = 3;
        };

        fill.symbol = " ";

        git_branch = {
          style = "#666666";
          symbol = "";
          format = "[$symbol$branch(:$remote_branch)]($style)";
        };

        git_status.style = "#666666";

        shell = {
          disabled = false;
          style = "cyan";
          bash_indicator = "";
          powershell_indicator = "";
        };

        username = {
          show_always = false;
          style_user = "#666666";
          format = "[$user]($style) ";
        };
      };
    };
  };
}
