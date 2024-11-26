{ lib, ... }:
let
  allTags = [
    "audio"
    "audio:midi"
    "audio:production"
    "boot:systemd"
    "bluetooth"
    "camera"
    "desktop:cosmic"
    "desktop:gnome"
    "desktop:hyprland"
    "desktop:remote"
    "filesystem:nfs"
    "fingerprint"
    "fonts"
    "gaming"
    "nvidia"
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
    "theming"
    "theming:catppuccin"
    "theming:dracula"
    "theming:nord"
    "thunderbolt"
    "v4l2loopback"
    "video:production"
    "virtualization:docker"
    "virtualization:podman"
    "virtualization:waydroid"
    "vnc"
    "work"
  ];

in
{
  types = {
    allTags = lib.types.listOf (lib.types.enum allTags);

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

    tags =
      let
        from = lib.mkOptionType {
          name = "tags";
          description = "tag or list of tags: [" + (lib.strings.concatStringsSep " " allTags) + "]";
          descriptionClass = "noun";
          check =
            v:
            if builtins.isString v then
              lib.hdwlinux.matchTag v allTags
            else if builtins.isList v then
              lib.hdwlinux.matchTags v allTags
            else
              false;
          merge = lib.options.mergeEqualOption;
        };
        coerce =
          v: tags:
          if builtins.isString v then lib.hdwlinux.matchTag v tags else lib.hdwlinux.matchTags v tags;
      in
      tags: lib.types.coercedTo from (v: coerce v tags) lib.types.bool;
  };
}
