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

  # Check if home-manager extension is enabled
  hasHomeManager = slib.hasClass "homeManager";
in
{
  flake.nixosConfigurations = lib.mapAttrs (
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
            usercfg = config.substrate.users.${user};
          in
          {
            name = usercfg.name;
            value = mkNixosUser usercfg;
          }
        ) hostcfg.users
      );

      hostNixosModules = slib.extractClassModules "nixos" (finder.find [ hostcfg ]);

      userNixosModules = slib.extractClassModules "nixos" (
        finder.find ([ hostcfg ] ++ (lib.map (user: config.substrate.users.${user}) hostcfg.users))
      );

      pkgs = import inputs.nixpkgs {
        system = hostcfg.system;
        config = hostcfg.nixpkgsConfig or { };
        overlays = allOverlays;
      };

      homeManagerModules = lib.optionals hasHomeManager [
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager =
            let
              mkHomeManagerUserModule = hostcfg: usercfg: {
                imports = slib.extractClassModules "homeManager" (
                  finder.find [
                    hostcfg
                    usercfg
                  ]
                );
                _module.args = slib.extraArgsGenerator {
                  inherit
                    hostcfg
                    usercfg
                    pkgs
                    inputs
                    ;
                };
              };
            in
            {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "bak";
              extraSpecialArgs = {
                inherit inputs;
                host = hostname;
              };
              sharedModules = settings.homeManagerModules or [ ];
              users = lib.listToAttrs (
                lib.map (
                  user:
                  let
                    usercfg = config.substrate.users.${user};
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
      specialArgs =
        (slib.extraArgsGenerator {
          inherit hostcfg pkgs inputs;
          usercfg = null;
        })
        // {
          inherit inputs;
        };
      modules = [
        {
          nixpkgs = {
            inherit pkgs;
            hostPlatform = hostcfg.system;
          };
          networking.hostName = lib.mkDefault hostname;
        }
        { users.users = nixosUsers; }
      ]
      ++ settings.nixosModules
      ++ slib.unique (hostNixosModules ++ userNixosModules)
      ++ homeManagerModules;
    }
  ) config.substrate.hosts;
}
