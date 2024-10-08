{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.starship;
in
{
  options.hdwlinux.features.starship = with types; {
    enable = mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
    settings = mkOpt attrs { } (mdDoc "Options to pass directly to `programs.starship.settings`.");
  };

  config.programs.starship = mkIf cfg.enable {
    enable = true;
    enableBashIntegration = config.hdwlinux.features.bash.enable;
    settings = {
      command_timeout = 5000;
      format = "$nix_shell$shell$username$hostname$directory$git_branch$git_commit$git_state$git_metrics$git_status$kubernetes$line_break$character";

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

      nix_shell = {
        symbol = "❄️ ";
        format = "[$symbol]($style)";
      };

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
    } // cfg.settings;
  };
}
