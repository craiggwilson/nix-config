{ pkgs, config, homeDirectory, ... }: {
    home.packages = with pkgs; [
        buf
    ];

    home.file."${config.xdg.configHome}/deckmaster" = {
        source = ./config;
        recursive = true;
    };

    systemd.user = {
		paths = {
			streamdeck = {
				Unit = {
					Description = "Streamdeck Device Path";
				};
				Path = {
					PathExists = "/dev/streamdeck";
					Unit = "deckmaster.service";
				};
				Install = {
					WantedBy = ["multi-user.target"];
				};
			};
		};
		services = {
			deckmaster = {
				Unit = {
					Description = "Deckmaster Service";
				};
				Service = {
					ProtectSystem = "full";
					ProtectHostname = true;
					ProtectKernelTunables = true;
					ProtectControlGroups = true;
					RestrictRealtime = true;
					ExecStart="${pkgs.deckmaster}/bin/deckmaster --deck ${homeDirectory}/.config/deckmaster/main.toml";
					Restart =" on-failure";
					RestartSec = 3;
					ExecReload = "kill -HUP $MAINPID";
				};
				Install = {
					WantedBy = ["default.target"];
				};
			};
		};
	};
}
