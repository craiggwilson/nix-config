# Flake-parts module for NixOS system configurations.
# Options and configuration are defined in flake.nix.
{
  inputs,
  lib,
  self,
  config,
  ...
}:
let
  # Extend lib with project lib using lib.extend to preserve extensibility
  # All keys from config.project.lib are merged into lib
  extendedLib = lib.extend (self: super: config.project.lib);

  # Create a NixOS configuration for a system
  mkSystem =
    name: systemDef:
    let
      # Handle both simple path and attrset with path/format
      path = if builtins.isAttrs systemDef then systemDef.path else systemDef;
      format = if builtins.isAttrs systemDef then (systemDef.format or null) else null;
      system =
        if builtins.isAttrs systemDef then (systemDef.system or "x86_64-linux") else "x86_64-linux";
      users = if builtins.isAttrs systemDef then (systemDef.users or [ ]) else [ ];

      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
      };

      # Look up home path for a user from config.project.homes
      getHomePath =
        userName:
        let
          homeDef = config.project.homes.${userName} or null;
        in
        if homeDef == null then
          throw "User '${userName}' not found in project.homes"
        else if builtins.isAttrs homeDef then
          homeDef.path
        else
          homeDef;

      # Generate home-manager.users config from users list
      homeUsersConfig = lib.listToAttrs (
        map (userName: {
          name = userName;
          value = {
            imports = [
              (getHomePath userName)
            ]
            ++ config.project.homeModules;
          };
        }) users
      );
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        lib = extendedLib;
      };
      modules =
        # Import all internal NixOS modules
        (map (p: import p) config.project.nixosModules)
        # External modules from flake.nix
        ++ config.project.external.nixosModules
        # System-specific configuration
        ++ [
          (import path)
          {
            nixpkgs = {
              inherit pkgs;
              hostPlatform = system;
            };
            networking.hostName = name;
          }
        ]
        # Include home modules in home-manager.sharedModules and homeUsers
        ++ [
          {
            home-manager.extraSpecialArgs = {
              inherit inputs;
              host = name;
            };
            home-manager.sharedModules = config.project.external.homeModules;
            home-manager.users = homeUsersConfig;
          }
        ]
        # ISO-specific configuration
        ++ lib.optional (format == "install-iso") (
          { modulesPath, ... }:
          {
            imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];
          }
        );
    };
in
{
  flake = {
    nixosConfigurations = lib.mapAttrs mkSystem config.project.nixosSystems;
  };
}
