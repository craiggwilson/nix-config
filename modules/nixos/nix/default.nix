{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config.hdwlinux.nix;

  substituters-submodule = lib.types.submodule (
    { ... }:
    {
      options = {
        key = lib.mkOption {
          description = "The trusted public key for this substituter.";
          type = (lib.types.nullOr lib.types.str);
          default = lib.types.null;
        };
      };
    }
  );
in
{
  options.hdwlinux.nix = {
    package = lib.mkOption {
      description = "Which nix package to use.";
      type = lib.types.package;
      default = pkgs.nixVersions.latest;
    };

    flake = lib.mkOption {
      description = "The git repository directory that holds the flake.";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    default-substituter = {
      url = lib.mkOption {
        description = "The url for the substituter.";
        type = lib.types.str;
        default = "https://cache.nixos.org";
      };

      key = lib.mkOption {
        description = "The trusted public key for the substituter.";
        type = lib.types.str;
        default = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
      };
    };

    extra-substituters = lib.mkOption {
      description = "Extra substituters to configure.";
      type = lib.types.attrsOf substituters-submodule;
      default = { };
    };
  };

  config = {
    assertions = lib.mapAttrsToList (name: value: {
      assertion = value.key != null;
      message = "hdwlinux.nix.extra-substituters.${name}.key must be set";
    }) cfg.extra-substituters;

    environment.systemPackages = with pkgs; [
      cacert
      deploy-rs
      nixfmt-rfc-style
      nix-index
      nix-prefetch-git
    ];

    environment.variables = {
      NIXPKGS_ALLOW_UNFREE = "1";
    };

    nixpkgs = {
      config.allowUnfree = true;
      flake = {
        setNixPath = true;
        setFlakeRegistry = true;
      };
    };

    programs.nix-ld = {
      enable = true;
    };

    system = {
      activationScripts.diff = ''
        if [[ -e /run/current-system ]]; then
          ${pkgs.nix}/bin/nix store diff-closures /run/current-system "$systemConfig"
        fi
      '';

      switch = {
        enable = false;
        enableNg = true;
      };
    };

    nix = {
      package = cfg.package;

      channel.enable = false;

      registry = {
        nixpkgs.flake = inputs.nixpkgs;
        stable.flake = inputs.nixpkgs-stable;
        unstable.flake = inputs.nixpkgs;
        hdwlinux.to = {
          type = "path";
          path = cfg.flake;
        };
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
        ] ++ (lib.mapAttrsToList (name: value: name) cfg.extra-substituters);
        trusted-public-keys = [
          cfg.default-substituter.key
        ] ++ (lib.mapAttrsToList (name: value: value.key) cfg.extra-substituters);
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
