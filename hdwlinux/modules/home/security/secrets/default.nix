{
  config,
  inputs,
  lib,
  pkgs,
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
          default = "${config.home.homeDirectory}/.config/hdwlinux/secrets/${name}";
          description = "Custom path for the secret file. Defaults to outputDir/secret name";
        };

        owner = lib.mkOption {
          type = lib.types.str;
          default = "${config.hdwlinux.user.name}";
          description = "User who owns the secret file";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "users";
          description = "Group that owns the secret file";
        };

        mode = lib.mkOption {
          type = lib.types.str;
          default = "0600";
          description = "File permissions in octal notation";
        };
      };
    }
  );

  templateType = lib.types.submodule {
    options = {
      owner = lib.mkOption {
        type = lib.types.str;
        default = "${config.hdwlinux.user.name}";
        description = "User who owns the secret file";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "users";
        description = "Group that owns the secret file";
      };
      mode = lib.mkOption {
        type = lib.types.str;
        default = "0600";
        description = "File permissions in octal notation";
      };
      source = lib.mkOption {
        type = lib.types.either lib.types.str lib.types.path;
        description = "Source file to replace";
      };
      replacements = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              secretPath = lib.mkOption {
                type = lib.types.str;
              };
              string = lib.mkOption {
                type = lib.types.str;
                description = "String to replace in the source file";
              };
            };
          }
        );
      };
      target = lib.mkOption {
        type = lib.types.str;
        description = "Target file to write the replacement to";
      };
    };
  };
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

    templates = lib.mkOption {
      type = lib.types.attrsOf templateType;
      default = { };
      description = "Templates to replace strings with secrets";
    };
  };

  config = lib.mkIf (cfg.enable && (cfg.entries != { })) {
    programs.onepassword-secrets = {
      enable = true;
      secrets = cfg.entries;
      tokenFile = "${config.home.homeDirectory}/.config/opnix/token";
    };

    home.activation.templateHdwlinuxSecrets =
      inputs.home-manager.lib.hm.dag.entryAfter [ "retrieveOpnixSecrets" ]
        ''
          ${lib.concatMapAttrsStringSep "\n" (_: template: ''
            echo "Creating ${template.target} from ${template.source}"
            $DRY_RUN_CMD cp ${template.source} ${template.target} && \
              chmod ${template.mode} ${template.target} && \
              chown ${template.owner}:${template.group} ${template.target}

            ${lib.concatMapStringsSep "\n" (replacement: ''
              echo "Replacing ${replacement.string} with secret from ${replacement.secretPath}"
              $DRY_RUN_CMD ${pkgs.replace-secret}/bin/replace-secret ${replacement.string} ${replacement.secretPath} ${template.target}
            '') template.replacements}
          '') cfg.templates}
        '';
  };
}
