{
  config.substrate.modules.hardware.graphics.displaylink = {
    tags = [ "capability:displaylink" ];
    nixos =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      let
        needsDisplaylink = builtins.any (m: m.displaylink or false) (
          builtins.attrValues (config.hdwlinux.hardware.monitors or { })
        );
      in
      {
        services.xserver.videoDrivers = lib.mkIf needsDisplaylink [ "displaylink" ];

        # DisplayLinkManager often comes back from suspend in a bad state:
        # evdi outputs keep stale modes or stay dark until the service is
        # restarted. nixpkgs' displaylink module signals resume via a legacy
        # FIFO (/tmp/PmMessagesPort_in), which doesn't revive it, so restart
        # for real once the system is back up (after nixpkgs' "R" echo).
        powerManagement.resumeCommands = lib.mkIf needsDisplaylink (
          lib.mkAfter ''
            ${lib.getExe' pkgs.systemd "systemctl"} restart dlm.service
          ''
        );

        # DisplayLinkManager can hang on stop (SIGTERM times out and needs
        # SIGKILL); cap the wait so a resume-triggered restart recovers
        # quickly instead of blocking for the default 90s.
        systemd.services.dlm.serviceConfig.TimeoutStopSec = lib.mkIf needsDisplaylink 15;
      };
  };
}
