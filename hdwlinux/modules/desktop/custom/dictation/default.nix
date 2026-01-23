{
  config.substrate.modules.desktop.custom.dictation = {
    tags = [ "dictation" ];

    homeManager =
      {
        lib,
        pkgs,
        hasTag,
        ...
      }:
      let
        # Use CUDA-enabled whisper-cpp if an NVIDIA GPU is configured
        whisperCpp =
          if hasTag "graphics:nvidia" then
            pkgs.whisper-cpp.override { cudaSupport = true; }
          else
            pkgs.whisper-cpp;

        whisperModel = pkgs.fetchurl {
          url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin";
          sha256 = "0mj3vbvaiyk5x2ids9zlp2g94a01l4qar9w109qcg3ikg0sfjdyc";
        };

        audioFile = "/tmp/dictation-recording.wav";
        pidFile = "/tmp/dictation.pid";
        modeFile = "/tmp/dictation-mode.txt";

        startScript = pkgs.writeShellScript "dictctl-start" ''
          set -euo pipefail
          mode="''${1:-clipboard}"

          # Check if already running
          if [ -f "${pidFile}" ] && kill -0 "$(cat ${pidFile})" 2>/dev/null; then
            notify-send "Dictation" "Already running" --icon=microphone-sensitivity-high
            exit 0
          fi

          # Store mode for stop script
          echo "$mode" > "${modeFile}"

          # Clear previous recording
          rm -f "${audioFile}"

          # Record audio using PipeWire (uses default source automatically)
          # 16kHz mono WAV is what whisper expects
          nohup ${pkgs.pipewire}/bin/pw-record \
            --rate 16000 \
            --channels 1 \
            "${audioFile}" \
            > /dev/null 2>&1 &

          echo $! > "${pidFile}"

          if [ "$mode" = "type" ]; then
            notify-send "Dictation" "Recording (will type)..." --icon=microphone-sensitivity-high
          else
            notify-send "Dictation" "Recording..." --icon=microphone-sensitivity-high
          fi
        '';

        stopScript = pkgs.writeShellScript "dictctl-stop" ''
          set -euo pipefail

          if [ ! -f "${pidFile}" ]; then
            notify-send "Dictation" "Not running" --icon=microphone-sensitivity-muted
            exit 0
          fi

          mode=$(cat "${modeFile}" 2>/dev/null || echo "clipboard")
          pid=$(cat "${pidFile}")

          if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            sleep 0.3
          fi

          rm -f "${pidFile}" "${modeFile}"

          # Check if we have a recording
          if [ ! -f "${audioFile}" ] || [ ! -s "${audioFile}" ]; then
            notify-send "Dictation" "No audio recorded" --icon=dialog-warning
            exit 0
          fi

          notify-send "Dictation" "Transcribing..." --icon=audio-x-generic

          # Transcribe the recording using whisper-cli
          transcript=$(${lib.getExe' whisperCpp "whisper-cli"} \
            --model "${whisperModel}" \
            --file "${audioFile}" \
            --language en \
            --no-timestamps \
            --output-txt \
            2>/dev/null | grep -v "^whisper_" | grep -v "^\[" | tr -s ' \n' ' ' | sed 's/^ *//;s/ *$//')

          rm -f "${audioFile}"

          if [ -n "$transcript" ]; then
            # Always copy to clipboard
            echo -n "$transcript" | ${pkgs.wl-clipboard}/bin/wl-copy

            # In type mode, also type the text at cursor position
            if [ "$mode" = "type" ]; then
              ${pkgs.wtype}/bin/wtype -- "$transcript"
              notify-send "Dictation" "Typed: $(echo "$transcript" | head -c 80)..." --icon=input-keyboard
            else
              notify-send "Dictation" "Copied: $(echo "$transcript" | head -c 80)..." --icon=edit-paste
            fi
          else
            notify-send "Dictation" "No speech detected" --icon=dialog-warning
          fi
        '';
      in
      {
        home.packages = [
          whisperCpp
          pkgs.wl-clipboard
          pkgs.wtype
          (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
            name = "dictctl";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.libnotify
              pkgs.pipewire
              pkgs.procps
              whisperCpp
              pkgs.wl-clipboard
              pkgs.wtype
            ];
            subcommands = {
              start = {
                "*" = "${startScript} clipboard";
                clipboard = "${startScript} clipboard";
                type = "${startScript} type";
              };
              stop = "${stopScript}";
              toggle = {
                "*" = ''
                  if [ -f "${pidFile}" ] && kill -0 "$(cat ${pidFile})" 2>/dev/null; then
                    ${stopScript}
                  else
                    ${startScript} clipboard
                  fi
                '';
                clipboard = ''
                  if [ -f "${pidFile}" ] && kill -0 "$(cat ${pidFile})" 2>/dev/null; then
                    ${stopScript}
                  else
                    ${startScript} clipboard
                  fi
                '';
                type = ''
                  if [ -f "${pidFile}" ] && kill -0 "$(cat ${pidFile})" 2>/dev/null; then
                    ${stopScript}
                  else
                    ${startScript} type
                  fi
                '';
              };
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
