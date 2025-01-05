{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.screen;
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
  options.hdwlinux.desktopManagers.hyprland.screen = {
    enable = lib.hdwlinux.mkEnableOption "screen" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
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
            show-menu =
              builtins.replaceStrings [ "screen-capture-menu.rasi" ] [ "${./screen-capture-menu.rasi}" ]
                (builtins.readFile ./screen-capture-menu.sh);
            window = "hyprshot -m window --clipboard-only";
          };
          record = {
            desktop = recordCommand "slurp -o";
            is-recording = "pgrep -x \"wl-screenrec\" > /dev/null";
            region = recordCommand "slurp";
            show-menu =
              builtins.replaceStrings [ "screen-record-menu.rasi" ] [ "${./screen-record-menu.rasi}" ]
                (builtins.readFile ./screen-record-menu.sh);
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
}
