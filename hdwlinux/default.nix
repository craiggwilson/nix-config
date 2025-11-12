{ config, lib, ... }:
let
  pins = import ../npins;
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
        settings.inputs.nixpkgs = config.inputs.nixpkgs.result;
      };
      home-manager = {
        settings.inputs.nixpkgs = config.inputs.nixpkgs.result;
      };
      kolide-launcher = {
        settings.inputs.nixpkgs = config.inputs.nixpkgs.result;
      };
      musnix = {
        settings.inputs.nixpkgs = config.inputs.nixpkgs.result;
      };
      opnix = {
        settings.inputs.nixpkgs = config.inputs.nixpkgs.result;
      };
      rust-overlay = {
        settings.inputs.nixpkgs = config.inputs.nixpkgs.result;
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
