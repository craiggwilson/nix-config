# Flake-parts module for Home Manager configurations.
# Options and configuration are defined in flake.nix.
{
  inputs,
  lib,
  self,
  config,
  ...
}:
let
  # Create a Home Manager configuration
  mkHome =
    name: homeDef:
    let
      # Handle both simple path and attrset with path/system
      path = if builtins.isAttrs homeDef then homeDef.path else homeDef;
      system = if builtins.isAttrs homeDef then (homeDef.system or "x86_64-linux") else "x86_64-linux";

      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
      };
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs;
      };
      # Override lib to include both project extensions and home-manager's hm lib
      lib = lib.extend (
        self: super: {
          hm = inputs.home-manager.lib.hm;
          hdwlinux = config.project.lib.hdwlinux;
        }
      );
      modules =
        # Import all internal Home Manager modules
        (map (p: import p) config.project.homeModules)
        # External modules from flake.nix
        ++ config.project.external.homeModules
        # Home-specific configuration
        ++ [
          (import path)
          {
            home = {
              username = name;
              homeDirectory = "/home/${name}";
            };
          }
        ];
    };
in
{
  flake = {
    homeConfigurations = lib.mapAttrs mkHome config.project.homes;
  };
}
