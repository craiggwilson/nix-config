{
  options,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.nix;

  substituters-submodule = types.submodule (
    { name, ... }:
    {
      options = with types; {
        key = mkOpt (nullOr str) null "The trusted public key for this substituter.";
      };
    }
  );
in
{
  options.hdwlinux.nix = with types; {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    package = mkOpt package pkgs.nixVersions.latest "Which nix package to use.";
    flake = mkOpt (nullOr str) null "The git repository directory that holds the flake.";

    default-substituter = {
      url = mkOpt str "https://cache.nixos.org" "The url for the substituter.";
      key =
        mkOpt str "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "The trusted public key for the substituter.";
    };

    extra-substituters = mkOpt (attrsOf substituters-submodule) { } "Extra substituters to configure.";
  };

  config = mkIf cfg.enable {
    assertions = mapAttrsToList (name: value: {
      assertion = value.key != null;
      message = "hdwlinux.nix.extra-substituters.${name}.key must be set";
    }) cfg.extra-substituters;

    environment.systemPackages = with pkgs; [
      cacert
      deploy-rs
      nixpkgs-fmt
      nix-index
      nix-prefetch-git
      nix-output-monitor
    ];

    environment.variables = {
      NIXPKGS_ALLOW_UNFREE = "1";
    };

    programs.nix-ld.enable = true;

    nix = {
      package = cfg.package;

      registry = {
        nixpkgs.flake = inputs.nixpkgs;
        stable.flake = inputs.nixpkgs-stable;
        unstable.flake = inputs.nixpkgs;
        #hdwlinux.flake = self;
      };

      settings = {
        experimental-features = "nix-command flakes";
        http-connections = 50;
        warn-dirty = false;
        log-lines = 50;
        sandbox = "relaxed";
        auto-optimise-store = true;
        trusted-users = [ "root" ];
        allowed-users = [ "root" ];
        keep-outputs = true;
        keep-derivations = true;
        substituters = [
          cfg.default-substituter.url
        ] ++ (mapAttrsToList (name: value: name) cfg.extra-substituters);
        trusted-public-keys = [
          cfg.default-substituter.key
        ] ++ (mapAttrsToList (name: value: value.key) cfg.extra-substituters);
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      # flake-utils-plus
      generateRegistryFromInputs = false;
      generateNixPathFromInputs = true;
      linkInputs = true;
    };
  };
}
