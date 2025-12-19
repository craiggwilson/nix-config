{
  config,
  lib,
}:
{
  flake = {
    homeConfigurations = lib.mapAttrs (
      username: cfg:
      let
        homeModules = [
          (import ./default.nix { inherit config lib; })
        ]
        ++ cfg.modules.homeManager;
      in
      lib.homeManagerConfiguration {
        inherit username;
        homeDirectory = cfg.homeDirectory;
        modules = homeModules;
      }
    ) config.users;

    nixosConfigurations = lib.mapAttrs (
      _: hostcfg:
      lib.nixosSystem {
        inherit (hostcfg) modules system;
      }
    ) config.hosts;
  };
}
