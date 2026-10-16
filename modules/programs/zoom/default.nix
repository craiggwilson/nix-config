{
  config.substrate.modules.programs.zoom = {
    provides = [ "programs:zoom" "gui" ];
    requires = [ "profiles:work" ];
    tags = [
      "gui"
      "users:craig:work"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = [ pkgs.zoom-us ];

        # Zoom must run as native Wayland (xwayland=false) for screen sharing
        # to work through the xdg-desktop-portal/PipeWire path; XWayland
        # capture shows black screens under niri. zoomus.conf is rewritten by
        # Zoom itself, so patch it in place instead of managing it as a
        # read-only store symlink.
        home.activation.zoomWaylandShare = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          conf="$HOME/.config/zoomus.conf"
          if [ -f "$conf" ]; then
            if grep -q '^xwayland=' "$conf"; then
              sed -i 's/^xwayland=.*/xwayland=false/' "$conf"
            else
              sed -i '/^\[General\]/a xwayland=false' "$conf"
            fi
          fi
        '';
      };
  };
}
