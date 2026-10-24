{
  config.substrate.modules.programs.handy = {
    tags = [ "desktop" ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = [ pkgs.handy ];

        systemd.user.services.handy = {
          Unit = {
            Description = "Handy speech-to-text service";
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${lib.getExe pkgs.handy} --start-hidden";
            Restart = "on-failure";
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };

        hdwlinux.desktop.actions = {
          toggleHandyTranscription = {
            binding = "Mod+O";
            command = [
              "handy"
              "--toggle-transcription"
            ];
            description = "Toggle dictation capture";
            showInHotkeyOverlay = true;
          };
          toggleHandyPostProcess = {
            binding = "Mod+Shift+O";
            command = [
              "handy"
              "--toggle-post-process"
            ];
            description = "Toggle dictation capture with post-processing";
            showInHotkeyOverlay = true;
          };
        };
      };
  };
}
