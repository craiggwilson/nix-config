{ pkgs, config, ... }: {
    programs.starship = {
        enable = true;
        enableBashIntegration = true;

        settings = {
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
}
