{
  config.substrate.modules.desktop.custom.dictation = {

    homeManager =
      { pkgs, ... }:
      let
        pidFile = "/tmp/dictation.pid";
        transcriptFile = "/tmp/dictation-out.txt";

        # Inline start/stop logic as strings so writeShellApplication's PATH
        # (runtimeInputs prepended) applies. scribe is intentionally NOT in
        # runtimeInputs — the full featured binary (CUDA, etc.) lives in
        # home.packages and is found via the user's PATH after runtimeInputs.
        startCmd = ''
          if [ -f "${pidFile}" ] && kill -0 "$(cat ${pidFile})" 2>/dev/null; then
            notify-send "Dictation" "Already running" --icon=microphone-sensitivity-high
            exit 0
          fi

          rm -f "${transcriptFile}"

          # Capture scribe's stdout to a temp file; SIGTERM triggers graceful shutdown.
          scribe capture --profile dictate > "${transcriptFile}" &
          echo $! > "${pidFile}"

          notify-send "Dictation" "Recording..." --icon=microphone-sensitivity-high
        '';

        stopCmd = ''
          if [ ! -f "${pidFile}" ]; then
            notify-send "Dictation" "Not running" --icon=microphone-sensitivity-muted
            exit 0
          fi

          pid=$(cat "${pidFile}")

          # SIGTERM triggers scribe's graceful shutdown; suppress error if already dead.
          kill -TERM "$pid" 2>/dev/null || true
          # wait(1) only works for child processes of the current shell, so poll instead.
          _timeout=100
          while kill -0 "$pid" 2>/dev/null && [ "$_timeout" -gt 0 ]; do
            sleep 0.1
            _timeout=$((_timeout - 1))
          done
          rm -f "${pidFile}"

          if [ ! -s "${transcriptFile}" ]; then
            notify-send "Dictation" "No speech detected" --icon=dialog-warning
            rm -f "${transcriptFile}"
            exit 0
          fi

          wl-copy < "${transcriptFile}"
          rm -f "${transcriptFile}"

          notify-send "Dictation" "Copied to clipboard" --icon=edit-paste
        '';
      in
      {
        home.packages = [
          pkgs.wl-clipboard
          (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
            name = "dictctl";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.libnotify
              pkgs.procps
              pkgs.wl-clipboard
            ];
            subcommands = {
              start = startCmd;
              stop = stopCmd;
              toggle = ''
                if [ -f "${pidFile}" ] && kill -0 "$(cat ${pidFile})" 2>/dev/null; then
                  ${stopCmd}
                else
                  ${startCmd}
                fi
              '';
              is-running = ''
                if [ -f "${pidFile}" ] && kill -0 "$(cat ${pidFile})" 2>/dev/null; then
                  exit 0
                else
                  exit 1
                fi
              '';
            };
          })
        ];
      };
  };
}
