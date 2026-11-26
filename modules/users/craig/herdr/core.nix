{
  config.substrate.modules.users.craig.herdr.core = {
    tags = [ "user:craig" ];

    homeManager =
      {
        pkgs,
        ...
      }:
      {
        home.packages = [ pkgs.hdwlinux.herdr-core ];

        # Always-on core: terminals and machines stay reachable after logout.
        # The core is guarded by core.lock, so this unit and the on-demand
        # `hc` autostart never double-serve — whoever holds the lock serves.
        systemd.user.services.herdr-core = {
          Unit = {
            Description = "herdr-core: terminals for coding agents";
            Documentation = "https://github.com/herdrdev/herdr-core";
          };
          Service = {
            ExecStart = "${pkgs.hdwlinux.herdr-core}/bin/herdr-core serve";
            Restart = "on-failure";
            # Terminals inherit the core's environment and the user manager
            # starts minimal, so carry the profile PATH: openssh for machine
            # connections, the user profile and system path for the agents
            # the terminals run.
            Environment = "PATH=/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin:%h/.local/bin";
          };
          Install.WantedBy = [ "default.target" ];
        };

        # Refresh the always-on service after UWSM publishes the graphical
        # session environment, which its boot-started process cannot inherit.
        systemd.user.services.herdr-core-session-refresh = {
          Unit = {
            Description = "Refresh herdr-core environment for graphical session";
            After = [ "graphical-session.target" ];
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl --user restart herdr-core.service";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };

    # Linger keeps the user manager — and the herdr-core service with it —
    # running from boot and across logouts, so remote machines can use this
    # box whenever it is on. This is the survival model herdr-core itself
    # documents for machines (docs/machines.md).
    nixos = {
      users.users.craig.linger = true;
    };
  };
}
