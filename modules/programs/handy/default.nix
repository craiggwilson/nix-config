{
  config.substrate.modules.programs.handy = {
    tags = [ "desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.handy ];

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
