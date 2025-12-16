{ lib, ... }:
let
  # Import types directly to avoid circular dependency with lib.hdwlinux
  typesLib = import ../types/default.nix { inherit lib; };
  hdwTypes = typesLib.types;
in
{
  # Shared option definitions used by both NixOS and Home Manager modules.
  # These define the data model for configuration that flows from NixOS to Home Manager.
  #
  # Note: Options with 'enable' flags that use tag-based types in NixOS should NOT
  # be included here. Instead, NixOS modules declare those options and pass the
  # evaluated values to Home Manager via home-manager.sharedModules.
  # To check if a feature is enabled, check if the relevant config value is non-empty
  # (e.g., tailscale.tailnet != "" means tailscale is enabled).
  sharedOptions = {
    apps = lib.mkOption {
      description = "List of categorical apps to reference generically.";
      type = lib.types.attrsOf hdwTypes.app;
      default = { };
    };

    flake = lib.mkOption {
      description = "The path to the flake source directory.";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    hardware = {
      audio.soundcard = lib.mkOption {
        description = "The soundcard information.";
        type = hdwTypes.pcicard;
        default = {
          busId = "";
          path = "";
        };
      };
      graphics = {
        card = lib.mkOption {
          description = "The graphics card information.";
          type = hdwTypes.pcicard;
          default = {
            busId = "";
            path = "";
          };
        };
        nvidia.card = lib.mkOption {
          description = "The nvidia graphics card information.";
          type = hdwTypes.pcicard;
          default = {
            busId = "";
            path = "";
          };
        };
      };
      monitors = lib.mkOption {
        description = "Options to set the monitor configuration.";
        type = lib.types.attrsOf hdwTypes.monitor;
        default = { };
      };
    };

    networking = {
      domain = lib.mkOption {
        description = "The domain to use for networking.";
        type = lib.types.str;
        default = "";
      };
      tailscale.tailnet = lib.mkOption {
        description = "The tailnet to use for tailscale. Empty string means tailscale is not configured.";
        type = lib.types.str;
        default = "";
      };
    };

    outputProfiles = lib.mkOption {
      description = "Options to set the output profiles.";
      type = lib.types.attrsOf hdwTypes.outputProfile;
      default = { };
    };

    tags = lib.mkOption {
      description = "Tags used to identify feature enablement.";
      type = hdwTypes.allTags;
      default = [ ];
    };
  };
}
