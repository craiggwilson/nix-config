{ lib, config, ... }:
let
  settings = config.substrate.settings;
  slib = config.substrate.lib;

  # All overlays come from settings.overlays (extensions add theirs there too)
  allOverlays = settings.overlays or [ ];

  mkHomeConfigurations =
    { inputs, substrate }:
    lib.mapAttrs (
      _: usercfg:
      let
        userPkgs = import inputs.nixpkgs {
          inherit (usercfg) system;
          overlays = allOverlays;
        };
        extraArgs = slib.extraArgsGenerator {
          inherit usercfg inputs;
          hostcfg = null;
        };
      in
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = userPkgs;
        extraSpecialArgs = extraArgs // {
          inherit inputs;
        };
        modules =
          (settings.homeManagerModules or [ ]) ++ (slib.findModulesForClass "homeManager" [ usercfg ]);
      }
    ) substrate.users;
in
{
  options.substrate.settings = {
    homeManagerModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      description = "External home-manager modules to include in all home-manager configurations.";
      default = [ ];
    };
  };

  config.substrate = {
    settings.supportedClasses = [ "homeManager" ];

    outputs.homeConfigurations = [
      {
        type = "global";
        build = { inputs, substrate }: mkHomeConfigurations { inherit inputs substrate; };
      }
    ];
  };
}
