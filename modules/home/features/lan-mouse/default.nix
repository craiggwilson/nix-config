{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.lan-mouse;
in
{
  options.hdwlinux.features.lan-mouse = {
    enable = lib.hdwlinux.mkBoolOpt false "Enable the lan-mouse feature.";
    client = lib.mkOption {
      type = lib.types.submodule {
        options = {
          direction = lib.mkOption {
            type = lib.types.enum [
              "left"
              "right"
              "up"
              "down"
            ];
          };
          hostname = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          ips = lib.mkOption { type = lib.types.nullOr (lib.types.listOf lib.types.str); };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.lan-mouse ];

    xdg.configFile."lan-mouse/config.toml".text = ''
      [${cfg.client.direction}]
      ${if cfg.client.hostname != null then "host_name = \"" + cfg.client.hostname + "\"" else ""}
      ${
        if cfg.client.ips != null then
          "ips = [" + lib.concatStringsSep ", " (builtins.map (ip: "\"${ip}\"") cfg.client.ips) + "]"
        else
          ""
      }
    '';

    systemd.user.services.lan-mouse = {
      Unit = {
        Description = "Mouse & keyboard sharing via LAN";
        Documentation = [ "https://github.com/feschber/lan-mouse" ];
        After = "graphical-session.target";
        Wants = "network-online.target";
      };
      Service = {
        ExecStart = "${pkgs.lan-mouse}/bin/lan-mouse --daemon";
        Restart = "on-failure";
        RestartSec = 3;
        BindTo = "graphical-session.target";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
