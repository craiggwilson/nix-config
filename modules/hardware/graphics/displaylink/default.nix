{
  config.substrate.modules.hardware.graphics.displaylink = {
    nixos =
      { config, lib, ... }:
      let
        needsDisplaylink = builtins.any (m: m.displaylink or false) (
          builtins.attrValues (config.hdwlinux.hardware.monitors or { })
        );
      in
      lib.mkIf needsDisplaylink {
        services.xserver.videoDrivers = [ "displaylink" ];

        # Keep DisplayLink USB devices out of autosuspend: after s2idle they can
        # re-enumerate without DisplayLinkManager re-attaching to the evdi node,
        # which leaves the monitor permanently disconnected until dlm is restarted.
        services.udev.extraRules = ''
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="17e9", ATTR{power/control}="on"
        '';

        # Belt and braces: if the device did vanish over suspend, restart dlm so
        # it re-opens the evdi card. Only when no evdi connector is live, to
        # avoid flickering a healthy setup.
        powerManagement.resumeCommands = ''
          if ! grep -qs '^connected' /sys/class/drm/card*-DVI-I-*/status; then
            ${config.systemd.package}/bin/systemctl try-restart dlm.service || true
          fi
        '';
      };
  };
}
