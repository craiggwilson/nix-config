{ config, lib, ... }:
let
  pins = import ../npins;
in
{
  config = {
    inherit pins;

    inputs = {
      nixpkgs = {
        settings = {
          config = {
            allowUnfree = true;
          };
        };
      };

      nixpkgs-flake = {
        loader = "flake";
        src = config.inputs.nixpkgs.src;
      };

      disko = {
        settings.inputs.nixpkgs = config.inputs.nixpkgs-flake;
      };
      home-manager = {
        settings.inputs.nixpkgs = config.inputs.nixpkgs-flake;
      };
      kolide-launcher = {
        settings.inputs.nixpkgs = config.inputs.nixpkgs-flake;
      };
      musnix = {
        settings.inputs.nixpkgs = config.inputs.nixpkgs-flake;
      };
      opnix = {
        settings.inputs.nixpkgs = config.inputs.nixpkgs-flake;
      };
      rust-overlay = {
        settings.inputs.nixpkgs = config.inputs.nixpkgs-flake;
      };
    };

    extraLibs = [ ./lib ];

    overlays = [
      config.inputs.rust-overlay.result.overlays.default
      ./overlays/calibre
      ./overlays/hdwlinux
      ./overlays/openssh
    ];

    packages = {
      atlas-cli.src = ./packages/atlas-cli;
      code42-aat-unwrapped.src = ./packages/code42-aat-unwrapped;
      engflow_auth.src = ./packages/engflow_auth;
      evergreen.src = ./packages/evergreen;
      falcon-sensor.src = ./packages/falcon-sensor;
      fern.src = ./packages/fern;
      island-browser-unwrapped.src = ./packages/island-browser-unwrapped;
      matcha.src = ./packages/matcha;
      mongo-orchestration.src = ./packages/mongo-orchestration;
      prisma-access-browser-unwrapped.src = ./packages/prisma-access-browser-unwrapped;
      songtool.src = ./packages/songtool;
    };

    systems.nixos.unsouled = {
      system = "x86_64-linux";
      specialArgs = {
        inherit pins;
        inputs = lib.mapAttrs (name: input: input.result) config.inputs;
      };
      pkgs = config.inputs.nixpkgs-flake.result.legacyPackages.x86_64-linux;
      modules = [
        ./systems/x86_64-linux/unsouled
        config.inputs.disko.result.nixosModules.default
        config.inputs.home-manager.result.nixosModules.default
        config.inputs.kolide-launcher.result.nixosModules.kolide-launcher
        config.inputs.musnix.result.nixosModules.musnix
        config.inputs.opnix.result.nixosModules.default
        ./modules/nixos
        config.inputs.nix-private.result.nixosModules.nix-private
      ];
    };
  };
}
