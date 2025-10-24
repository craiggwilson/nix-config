{ config, lib, ... }:
let
  pins = import ../npins;
  nixpkgs-flake = config.inputs.nixpkgs-unstable.result;
in
{
  config = {
    inherit pins;

    inputs = {
      nixpkgs = {
        src = pins.nixpkgs-unstable;
        settings = {
          config = {
            allowUnfree = true;
          };
        };
      };

      disko = {
        settings.inputs.nixpkgs = nixpkgs-flake;
      };

      home-manager = {
        settings.inputs.nixpkgs = nixpkgs-flake;
      };

      kolide-launcher = {
        settings.inputs.nixpkgs = nixpkgs-flake;
      };

      musnix = {
        settings.inputs.nixpkgs = nixpkgs-flake;
      };

      opnix = {
        settings.inputs.nixpkgs = nixpkgs-flake;
      };

      rust-overlay = {
        settings.inputs.nixpkgs = nixpkgs-flake;
      };
    };

    custom = {
      libs = [ ./lib ];
      overlays = [
        config.inputs.rust-overlay.result.overlays.default
        ./overlays/calibre
        ./overlays/hdwlinux
        ./overlays/openssh
      ];
    };

    systems.nixos.unsouled = {
      system = "x86_64-linux";
      args = {
        inputs = lib.mapAttrs (name: input: input.result) config.inputs;
      };
      modules = [
        ./systems/x86_64-linux/unsouled
        config.inputs.disko.result.nixosModules.default
        config.inputs.home-manager.result.nixosModules.default
        config.inputs.kolide-launcher.result.nixosModules.kolide-launcher
        config.inputs.musnix.result.nixosModules.musnix
        config.inputs.opnix.result.nixosModules.default
        ./modules/nixos
      ];
    };
  };
}
