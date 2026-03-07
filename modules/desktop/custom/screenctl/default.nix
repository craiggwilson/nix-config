{
  config.substrate.modules.desktop.custom.screenctl = {
    tags = [ "desktop:custom" ];

    homeManager =
      { pkgs, ... }:
      let
        recordCommand = slurp: ''
          filename="$HOME/Videos/$(date +'screenrecord_%Y%m%d%H%M%S.mp4')"
          thumbnail='/tmp/screenrec_thumbnail.png'
          nohup "$SHELL" << EOF >/dev/null 2>&1 &
          wl-screenrec --filename "$filename" -g "$(${slurp})" &&
          ffmpeg -i "$filename" -ss 00:00:00 -vframes 1 "$thumbnail" -y &&
          notify-send "Recording saved" "Saved to $filename" --icon "$thumbnail"
          EOF
        '';
      in
      {
        home.packages = [
          (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
            name = "screenctl";
            runtimeInputs = [
              pkgs.brightnessctl
              pkgs.ffmpeg
              pkgs.hyprshot
              pkgs.procps
              pkgs.slurp
              pkgs.wl-screenrec
            ];
            subcommands = {
              backlight = {
                "*" = "brightnessctl";
                get = "brightnessctl get";
                lower = "brightnessctl set 5%-";
                raise = "brightnessctl set 5%+";
                restore = "brightnessctl -r";
                set = "brightnessctl -s set \"$1\"";
              };
              capture = {
                desktop = "hyprshot -m output --clipboard-only";
                region = "hyprshot -m region --clipboard-only";
                show-menu = builtins.readFile ./screen-capture-menu.sh;
                window = "hyprshot -m window --clipboard-only";
              };
              power = {
                # These are placeholder commands - compositor-specific power controls
                # should be configured in the compositor module
                off = "echo 'screenctl power off not configured for this compositor'";
                on = "echo 'screenctl power on not configured for this compositor'";
              };
              record = {
                desktop = recordCommand "slurp -o";
                is-recording = "pgrep -x \"wl-screenrec\" > /dev/null";
                region = recordCommand "slurp";
                show-menu = builtins.readFile ./screen-record-menu.sh;
                stop = "pkill --signal SIGINT \"wl-screenrec\"";
                watch = ''
                  while true; do 
                      if screenctl record is-recording; then
                          echo '󰑊'
                      else 
                          echo ""
                      fi
                      sleep 1; 
                  done
                '';
                window = recordCommand ''
                  hyprctl clients -j \
                    | jq -r ".[] | select(.workspace.id \
                    | IN($(hyprctl -j monitors | jq 'map(.activeWorkspace.id) | join(",")' | tr -d \")))" \
                    | jq -r ".at,.size" \
                    | jq -s "add" \
                    | jq '_nwise(4)' \
                    | jq -r '"\(.[0]),\(.[1]) \(.[2])x\(.[3])"' \
                    | slurp
                '';
              };
            };
          })
        ];
      };
  };
}

