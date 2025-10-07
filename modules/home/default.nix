{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux;
in
{
  options.hdwlinux = {
    apps = lib.mkOption {
      description = "List of categorical apps to reference generically.";
      type = lib.types.attrsOf lib.hdwlinux.types.app;
      default = { };
    };

    hardware = {
      audio.soundcard = lib.mkOption {
        description = "The soundcard information.";
        type = lib.hdwlinux.types.pcicard;
      };
      graphics = {
        card = lib.mkOption {
          description = "The intel video card information.";
          type = lib.hdwlinux.types.pcicard;
        };
        nvidia.card = lib.mkOption {
          description = "The nvidia graphics card information.";
          type = lib.hdwlinux.types.pcicard;
        };
      };
      monitors = lib.mkOption {
        description = "Options to set the monitor configuration.";
        type = lib.types.attrsOf lib.hdwlinux.types.monitor;
      };
    };

    mcpServers = lib.mkOption {
      description = "Options to set the mcp servers.";
      type = lib.types.attrsOf lib.hdwlinux.types.mcpServer;
    };

    outputProfiles = lib.mkOption {
      description = "Options to set the output profiles.";
      type = lib.types.attrsOf lib.hdwlinux.types.outputProfile;
    };

    tags = lib.mkOption {
      description = "Tags used to identify feature enablement.";
      type = lib.hdwlinux.types.allTags;
      default = [ ];
    };
  };

  config = {
    lib.hdwlinux = {
      mkEnableOption =
        name: default:
        lib.mkOption {
          description = "Whether to enable ${name}";
          type = lib.hdwlinux.types.tags cfg.tags;
          default = default;
        };
    };
  };
}
