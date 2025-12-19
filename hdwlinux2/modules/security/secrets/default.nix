{ lib, ... }:
{
  config.substrate.modules.security.secrets = {
    tags = [ "security:secrets" ];
    nixos =
      { config, lib, ... }:
      let
        cfg = config.hdwlinux.security.secrets;
      in
      {
        options.hdwlinux.security.secrets = {
          entries = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
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
                      description = "Services that depend on this secret";
                    };
                  };
                }
              )
            );
            default = { };
            description = "Declarative secrets configuration.";
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

        config = lib.mkIf (cfg.entries != { }) {
          services.onepassword-secrets = {
            enable = true;
            tokenFile = "/etc/opnix-token";
            outputDir = cfg.outputDir;
            secrets = cfg.entries;
            users = cfg.users;
          };
        };
      };

    homeManager =
      {
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.security.secrets;
      in
      {
        options.hdwlinux.security.secrets = {
          entries = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
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
                      description = "Custom path for the secret file.";
                    };

                    owner = lib.mkOption {
                      type = lib.types.str;
                      default = config.home.username;
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
              )
            );
            default = { };
            description = "Declarative secrets configuration.";
          };

          templates = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  owner = lib.mkOption {
                    type = lib.types.str;
                    default = config.home.username;
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
              }
            );
            default = { };
            description = "Templates to replace strings with secrets";
          };
        };

        config = lib.mkIf (cfg.entries != { }) {
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
      };
  };
}
