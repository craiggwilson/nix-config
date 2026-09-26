# Substrate extension: the "perUser" module class.
#
# Declared here (not in substrate) until proven out; move verbatim to
# substrate/extensions/per-user when stable. Depends only on substrate core
# APIs (findModulesForClass, extraArgsGenerator, settings options).
#
# Flow: perUser blocks in modules/ are evaluated per (host, user) pair at
# NixOS-build time and rendered into native NixOS config (users.users.*.packages,
# systemd.user.* units guarded by ConditionUser, per-user link scripts).
# No home-manager involved.
{ lib, config, ... }:
let
  settings = config.substrate.settings;
  slib = config.substrate.lib;

  # Evaluated inside nixosSystem (hence hostcfg/inputs from specialArgs), so
  # the per-user evaluation only runs for hosts that actually have users.
  perUserNixosModule =
    { inputs, hostcfg, pkgs, ... }:
    import ./to-nixos.nix {
      inherit
        lib
        inputs
        hostcfg
        slib
        pkgs
        ;
      usercfgOf = userKey: config.substrate.users.${userKey};
      allOverlays = settings.overlays or [ ];
    };
in
{
  config.substrate.settings = {
    supportedClasses = [ "perUser" ];

    # nixosModules items must be attrsets; the lambda rides inside imports.
    nixosModules = [
      {
        imports = [ perUserNixosModule ];
      }
    ];
  };
}
