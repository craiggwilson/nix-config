{ lib, ... }:
let
  availableTags = [
    "audio"
    "audio:midi"
    "audio:production"
    "boot:systemd"
    "bluetooth"
    "camera"
    "cli"
    "desktop:cosmic"
    "desktop:gnome"
    "desktop:hyprland"
    "desktop:remote"
    "filesystem:nfs"
    "fingerprint"
    "fonts"
    "gaming"
    "gui"
    "laptop"
    "networking"
    "networking:tailscale"
    "personal"
    "printing"
    "programming"
    "raeford"
    "scanning"
    "security:passwordmanager"
    "thunderbolt"
    "v4l2loopback"
    "video:nvidia"
    "video:production"
    "virtualization:docker"
    "virtualization:podman"
    "virtualization:waydroid"
    "vnc"
  ];
in
{
  pcicard = lib.types.submodule {
    options = {
      busId = lib.mkOption {
        description = "The PCI bus id. You can find it using lspci.";
        type = lib.types.strMatching "([0-9a-f]{1,3}[\:][0-9a-f]{1,2}[\.][0-9a-f])?";
        example = "01:00.0";
      };
      path = lib.mkOption {
        description = "The path to the card.";
        type = lib.types.str;
      };
    };
  };

  tags = lib.types.listOf (lib.types.enum availableTags);
}
