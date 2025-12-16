{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.desktopEnvironments.wayland.shikane;

  tomlFormat = pkgs.formats.toml { };

  mapProfiles = {
    profile = lib.mapAttrsToList (name: profile: {
      name = name;
      exec = profile.execs ++ [ "notify-send shikane \"$SHIKANE_PROFILE_NAME profile applied.\"" ];
      output = mapProfileOutputs profile.outputs;
    }) config.hdwlinux.outputProfiles;
  };

  mapProfileOutputs =
    outputs:
    lib.mapAttrsToList (
      monitorName: output:
      let
        monitor = config.hdwlinux.hardware.monitors.${monitorName};
      in
      {
        enable = output.enable;
        search = [
          "v=${monitor.vendor}"
          "m=${monitor.model}"
        ]
        ++ (if monitor.serial != null then [ "s=${monitor.serial}" ] else [ ]);
      }
      // (
        if output.enable then
          {
            exec =
              if config.hdwlinux.desktopEnvironments.wayland.hyprland.enable then
                output.execs
                ++ (lib.lists.flatten (
                  builtins.map (workspace: [
                    "hyprctl dispatch workspace \"${workspace}\""
                    "hyprctl keyword workspace \"${workspace}\", monitor:$SHIKANE_OUTPUT_NAME,persistent:true"
                    "hyprctl dispatch moveworkspacetomonitor \"${workspace}\" \"$SHIKANE_OUTPUT_NAME\""
                  ]) output.workspaces
                ))
              else
                output.execs;
            adaptive_sync = monitor.adaptive_sync;
            mode = monitor.mode;
            position = output.position;
            scale = monitor.scale;
            transform = output.transform;
          }
        else
          { }
      )
    ) outputs;
in
{
  options.hdwlinux.desktopEnvironments.wayland.shikane = {
    enable = config.lib.hdwlinux.mkEnableOption "shikane" config.hdwlinux.desktopEnvironments.wayland.enable;
  };

  config = lib.mkIf cfg.enable {

    home.packages = [
      pkgs.shikane
    ];

    xdg.configFile."shikane/config.toml" = {
      source = "${tomlFormat.generate "shikane" mapProfiles}";
    };

    systemd.user.services.shikane = {
      Unit = {
        Description = "Dynamic output configuration tool";
        Documentation = [ "https://gitlab.com/w0lff/shikane`" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.shikane}/bin/shikane -c" + config.xdg.configFile."shikane/config.toml".target;
        ExecReload = "${pkgs.shikane}/bin/shikanectl reload";
        Restart = "on-failure";
        Slice = "background-graphical.slice";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
