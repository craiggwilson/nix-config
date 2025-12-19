{
  lib,
  config,
  inputs,
  ...
}:
let
  settings = config.substrate.settings;
  slib = config.substrate.lib;
  finder = config.substrate.finders.${settings.finder};
  allOverlays = slib.mkAllOverlays;
  hasHomeManager = slib.hasClass "homeManager";
in
{
  flake.homeConfigurations = lib.mkIf hasHomeManager (
    lib.mapAttrs (
      _: usercfg:
      let
        userPkgs = import inputs.nixpkgs {
          inherit (usercfg) system;
          config.allowUnfree = true;
          overlays = allOverlays;
        };
        extraArgs = slib.extraArgsGenerator {
          inherit usercfg;
          hostcfg = null;
        };
      in
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = userPkgs;
        extraSpecialArgs = extraArgs // {
          inherit inputs;
        };
        modules =
          (settings.homeManagerModules or [ ])
          ++ (slib.extractClassModules "homeManager" (finder.find [ usercfg ]));
      }
    ) config.substrate.users
  );
}
