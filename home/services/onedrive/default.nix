{ pkgs, config, ... }: {
    home.packages = with pkgs; [
        onedrive
    ];

    home.file."${config.xdg.configHome}/onedrive" = {
        source = ./config;
        recursive = true;
    };

    systemd.user.services.onedrive = {
        Unit = {
            Description = "OneDrive Free Client";
            Documentation = ["https://github.com/abraunegg/onedrive"];
            After = "network-online.target";
            Wants = "network-online.target";
        };
        Service = {
            ProtectSystem = "full";
            ProtectHostname = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            RestrictRealtime = true;
            ExecStart = "${pkgs.onedrive}/bin/onedrive --monitor";
            Restart = "on-failure";
            RestartSec = 3;
            RestartPreventExitStatus = 3;
        };
        Install = {
            WantedBy = ["default.target"];
        };
    };
}