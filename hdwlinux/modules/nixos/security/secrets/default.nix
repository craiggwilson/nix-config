{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.security.secrets;

  secretType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        reference = lib.mkOption {
          type = lib.types.str;
          description = "1Password reference in the format op://Vault/Item/field";
        };

        path = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "${cfg.outputDir}/${name}";
          description = "Custom path for the secret file. Defaults to outputDir/secret name";
        };

        symlinks = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "List of symlink paths that should point to this secret";
        };

        owner = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = "User who owns the secret file";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = "Group that owns the secret file";
        };

        mode = lib.mkOption {
          type = lib.types.str;
          default = "0600";
          description = "File permissions in octal notation";
        };

        services = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
    }
  );
in
{
  options.hdwlinux.security.secrets = {
    enable = lib.hdwlinux.mkEnableOption "secrets" true;

    entries = lib.mkOption {
      type = lib.types.attrsOf secretType;
      default = { };
      description = ''
        Declarative secrets configuration (GitHub #11).
        Keys are secret names, values are secret configurations.
      '';
    };

    outputDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/hdwlinux/secrets";
      description = "Directory to store retrieved secrets.";
    };

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users that should have access to the secrets token through group membership.";
    };
  };

  config = lib.mkIf (cfg.enable && (cfg.entries != { })) {
    services.onepassword-secrets = {
      enable = true;
      tokenFile = "/etc/opnix-token";
      outputDir = cfg.outputDir;
      secrets = cfg.entries;
      users = cfg.users;
    };
  };
}
