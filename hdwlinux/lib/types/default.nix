{ lib }:
let
  allTags = [
    "audio"
    "audio:midi"
    "audio:production"
    "boot:systemd"
    "bluetooth"
    "camera"
    "cuda"
    "desktop:hyprland"
    "desktop:niri"
    "desktop:remote"
    "filesystem:nfs"
    "fingerprint"
    "fonts"
    "gaming"
    "gaming:streaming"
    "gui"
    "laptop"
    "networking"
    "networking:tailscale"
    "nvidia"
    "personal"
    "printing"
    "programming"
    "raeford"
    "scanning"
    "security:passwordmanager"
    "theming"
    "theming:catppuccin"
    "theming:dracula"
    "theming:nord"
    "thunderbolt"
    "users:craig"
    "v4l2loopback"
    "video:production"
    "virtualization:docker"
    "virtualization:podman"
    "virtualization:waydroid"
    "vnc"
    "work"
    "yubikey"
  ];

in
{
  allTags = lib.types.listOf (lib.types.enum allTags);

  app = lib.types.submodule {
    options = {
      package = lib.mkOption {
        description = "The path to the app's executable.";
        type = lib.types.package;
      };
      program = lib.mkOption {
        description = "The program name to invoke. If left null, will use the mainProgram from the package.";
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      argGroups = lib.mkOption {
        description = "Pre-packaged args.";
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
      };
      desktopName = lib.mkOption {
        description = "The name of the .desktop file to use for file associations.";
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };
  };

  mcpServer = lib.types.submodule {
    options = {
      type = lib.mkOption {
        description = "The transport type for the MCP server.";
        type = lib.types.enum [
          "stdio"
          "http"
          "sse"
        ];
        default = "stdio";
      };
      command = lib.mkOption {
        description = "The command to run.";
        type = lib.types.str;
      };
      args = lib.mkOption {
        description = "The arguments to pass to the command.";
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };

  monitor = lib.types.submodule {
    options = {
      model = lib.mkOption { type = lib.types.str; };
      serial = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      vendor = lib.mkOption { type = lib.types.str; };
      mode = lib.mkOption { type = lib.types.str; };
      scale = lib.mkOption { type = lib.types.float; };
      adaptive_sync = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      displaylink = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  outputProfile = lib.types.submodule {
    options = {
      execs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };

      outputs = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              monitor = lib.mkOption { type = lib.types.str; };
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              execs = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
              position = lib.mkOption { type = lib.types.str; };
              transform = lib.mkOption {
                type = lib.types.str;
                default = "normal";
              };
              workspaces = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
            };
          }
        );
      };
    };
  };

  pcicard = lib.types.submodule {
    options = {
      busId = lib.mkOption {
        description = "The PCI bus id. You can find it using lspci.";
        type = lib.types.strMatching "([0-9a-f]{1,3}[\:][0-9a-f]{1,2}[\.][0-9a-f])?";
        example = "01:00.0";
      };
      path = lib.mkOption {
        description = "The path to the card.";
        type = lib.types.str;
      };
    };
  };

  tags =
    let
      from = lib.mkOptionType {
        name = "tags";
        description = "tag or list of tags: [" + (lib.strings.concatStringsSep " " allTags) + "]";
        descriptionClass = "noun";
        check =
          v:
          if builtins.isString v then
            lib.hdwlinux.matchTag v allTags
          else if builtins.isList v then
            lib.hdwlinux.matchTags v allTags
          else
            false;
        merge = lib.options.mergeEqualOption;
      };
      coerce =
        v: tags:
        if builtins.isString v then lib.hdwlinux.matchTag v tags else lib.hdwlinux.matchTags v tags;
    in
    tags: lib.types.coercedTo from (v: coerce v tags) lib.types.bool;
}
