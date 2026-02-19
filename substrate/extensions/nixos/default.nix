{ lib, config, ... }:
let
  settings = config.substrate.settings;
  slib = config.substrate.lib;

  # All overlays come from settings.overlays
  allOverlays = settings.overlays or [ ];

  # Check if home-manager extension is enabled
  hasHomeManager = slib.hasClass "homeManager";

  mkNixosConfigurations =
    { inputs, substrate }:
    lib.mapAttrs (
      hostname: hostcfg:
      let
        mkNixosUser = usercfg: {
          isNormalUser = lib.mkDefault true;
          name = usercfg.name;
          group = lib.mkDefault "users";
        };

        nixosUsers = lib.listToAttrs (
          lib.map (
            user:
            let
              usercfg = substrate.users.${user};
            in
            {
              name = usercfg.name;
              value = mkNixosUser usercfg;
            }
          ) hostcfg.users
        );

        hostNixosModules = slib.findModulesForClass "nixos" [ hostcfg ];

        userConfigs = lib.map (user: substrate.users.${user}) hostcfg.users;
        userNixosModules = slib.findModulesForClass "nixos" ([ hostcfg ] ++ userConfigs);

        # Extra args for NixOS modules (e.g., hasTag from tags extension)
        nixosExtraArgs = slib.extraArgsGenerator {
          inherit hostcfg inputs;
          usercfg = null;
        };

        homeManagerModules = lib.optionals hasHomeManager [
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager =
              let
                mkHomeManagerUserModule = hostcfg: usercfg: {
                  imports = slib.findModulesForClass "homeManager" [
                    hostcfg
                    usercfg
                  ];
                  # Extra args for home-manager modules (e.g., hasTag from tags extension)
                  _module.args = slib.extraArgsGenerator {
                    inherit hostcfg usercfg inputs;
                  };
                };
              in
              {
                useGlobalPkgs = lib.mkDefault true;
                useUserPackages = lib.mkDefault true;
                backupFileExtension = lib.mkDefault "bak";
                extraSpecialArgs = {
                  inherit inputs hostcfg;
                  host = hostname;
                };
                sharedModules = settings.homeManagerModules or [ ];
                users = lib.listToAttrs (
                  lib.map (
                    user:
                    let
                      usercfg = substrate.users.${user};
                    in
                    {
                      name = usercfg.name;
                      value = mkHomeManagerUserModule hostcfg usercfg;
                    }
                  ) hostcfg.users
                );
              };
          }
        ];
      in
      inputs.nixpkgs.lib.nixosSystem {
        inherit (hostcfg) system;
        specialArgs = {
          inherit inputs hostcfg;
        };
        modules = [
          {
            nixpkgs = {
              overlays = allOverlays;
              hostPlatform = hostcfg.system;
            };
            networking.hostName = lib.mkDefault hostname;
            _module.args = nixosExtraArgs;
          }
          { users.users = nixosUsers; }
        ]
        ++ settings.nixosModules
        ++ slib.unique (hostNixosModules ++ userNixosModules)
        ++ homeManagerModules;
      }
    ) substrate.hosts;
in
{
  config.substrate = {
    settings.supportedClasses = [ "nixos" ];

    outputs.nixosConfigurations = [
      {
        type = "global";
        build = { inputs, substrate }: mkNixosConfigurations { inherit inputs substrate; };
      }
    ];
  };
}
