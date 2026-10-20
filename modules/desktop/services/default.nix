{
  config.substrate.modules.desktop.services = {
    tags = [ "desktop" ];

    # Common desktop services shared across shells (shikane, udiskie).
    # Each service can be disabled globally or per shell, mirroring the action
    # commandOverride pattern, so future monolithic desktops (Gnome/KDE/Cosmic)
    # can opt out of a service that their own stack provides.

    generic =
      { lib, ... }:
      {
        options.hdwlinux.desktop.services = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              # Service modules may attach extra config (e.g. udiskie's
              # trayOverride) alongside the shared gating flags.
              freeformType = lib.types.attrs;
              options = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Whether to enable the service.";
                };
                enableOverride = lib.mkOption {
                  type = lib.types.attrsOf lib.types.bool;
                  default = { };
                  description = "Per-shell overrides; false disables the service in that shell.";
                };
              };
            }
          );
          # Attribute names exist only once a module defines them; each service
          # module seeds its own entry with mkDefault, so no enumeration here.
          default = { };
          description = "Common desktop services shared across shells.";
        };
      };
  };
}
