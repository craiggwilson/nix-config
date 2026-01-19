{ lib, ... }:
{
  config.substrate.modules.security.secrets = {
    tags = [ "security:secrets" ];
    nixos =
      {
        config,
        lib,
        inputs,
        ...
      }:
      let
        cfg = config.hdwlinux.security.secrets;
      in
      {
        imports = [ inputs.opnix.nixosModules.default ];

        options.hdwlinux.security.secrets = {
          entries = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
                { name, ... }:
                {
                  options = {
                    source = lib.mkOption {
                      type = lib.types.enum [
                        "op"
                        "manual"
                      ];
                      default = "op";
                      description = "Source of the secret. Use 'op' for 1Password, 'manual' for manually managed secrets.";
                    };

                    reference = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "1Password reference in the format op://Vault/Item/field. Required when source is 'op'.";
                    };

                    path = lib.mkOption {
                      type = lib.types.str;
                      default = "${cfg.outputDir}/${name}";
                      description = "Path for the secret file. Defaults to outputDir/secret name";
                    };

                    symlinks = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      description = "List of symlink paths that should point to this secret. Only used when source is 'op'.";
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
                      description = "Services that depend on this secret. Only used when source is 'op'.";
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

        config =
          let
            opEntries = lib.filterAttrs (_: v: v.source == "op") cfg.entries;
            hasOpEntries = opEntries != { };
          in
          lib.mkIf hasOpEntries {
            services.onepassword-secrets = {
              enable = true;
              tokenFile = "/etc/opnix-token";
              outputDir = cfg.outputDir;
              secrets = lib.mapAttrs (_: v: builtins.removeAttrs v [ "source" ]) opEntries;
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
        imports = [ inputs.opnix.homeManagerModules.default ];

        options.hdwlinux.security.secrets = {
          entries = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
                { name, config, ... }:
                {
                  options = {
                    source = lib.mkOption {
                      type = lib.types.enum [
                        "op"
                        "manual"
                      ];
                      default = "op";
                      description = "Source of the secret. Use 'op' for 1Password, 'manual' for manually managed secrets.";
                    };

                    reference = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "1Password reference in the format op://Vault/Item/field. Required when source is 'op'.";
                    };

                    path = lib.mkOption {
                      type = lib.types.str;
                      default = "${cfg.outputDir}/${name}";
                      description = "Path for the secret file.";
                    };

                    owner = lib.mkOption {
                      type = lib.types.str;
                      default = cfg.defaultOwner;
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

          outputDir = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/.config/hdwlinux/secrets";
            description = "Directory to store secrets.";
          };

          defaultOwner = lib.mkOption {
            type = lib.types.str;
            default = config.home.username;
            description = "Default owner for secret files.";
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

        config =
          let
            opEntries = lib.filterAttrs (_: v: v.source == "op") cfg.entries;
            hasOpEntries = opEntries != { };
            manualEntries = lib.filterAttrs (_: v: v.source == "manual") cfg.entries;

            # Generate the secrets list script content
            secretsListScript =
              let
                secretsList = lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (
                    name: entry:
                    "  ${name}:\\n    path: ${entry.path}\\n    source: ${entry.source}\\n    owner: ${entry.owner}:${entry.group}\\n    mode: ${entry.mode}"
                  ) cfg.entries
                );
              in
              ''
                echo "Configured secrets:"
                ${if cfg.entries == { } then ''echo "  (none)"'' else ''echo -e "${secretsList}"''}
              '';

            # Generate the secrets set script with configured values
            secretsSetScript =
              let
                secretCases = lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (name: entry: ''
                    "${name}")
                      secret_path="${entry.path}"
                      secret_owner="${entry.owner}"
                      secret_group="${entry.group}"
                      secret_mode="${entry.mode}"
                      ;;'') manualEntries
                );
              in
              ''
                name=""

                # Parse arguments
                while [[ $# -gt 0 ]]; do
                  case "$1" in
                    *)
                      if [[ -z "$name" ]]; then
                        name="$1"
                        shift
                      else
                        echo "Error: Unknown argument '$1'" >&2
                        echo "Usage: hdwlinux secrets set <name>" >&2
                        exit 1
                      fi
                      ;;
                  esac
                done

                if [[ -z "$name" ]]; then
                  echo "Error: Secret name is required." >&2
                  echo "Usage: hdwlinux secrets set <name>" >&2
                  echo ""
                  echo "Available manual secrets:"
                  ${
                    if manualEntries == { } then
                      ''echo "  (none configured)"''
                    else
                      ''echo "${lib.concatStringsSep "\n" (lib.mapAttrsToList (n: _: "  ${n}") manualEntries)}"''
                  }
                  exit 1
                fi

                # Look up secret configuration
                case "$name" in
                ${secretCases}
                  *)
                    echo "Error: Unknown secret '$name'" >&2
                    echo ""
                    echo "Available manual secrets:"
                    ${
                      if manualEntries == { } then
                        ''echo "  (none configured)"''
                      else
                        ''echo "${lib.concatStringsSep "\n" (lib.mapAttrsToList (n: _: "  ${n}") manualEntries)}"''
                    }
                    exit 1
                    ;;
                esac

                # Read value from stdin (never from command line to avoid history)
                echo "Enter secret value for '$name' (input hidden):"
                read -rs value
                echo

                if [[ -z "$value" ]]; then
                  echo "Error: No secret value provided." >&2
                  exit 1
                fi

                # Create directory and write secret
                secret_dir=$(dirname "$secret_path")
                mkdir -p "$secret_dir"
                echo "$value" > "$secret_path"
                chmod "$secret_mode" "$secret_path"
                chown "$secret_owner:$secret_group" "$secret_path" 2>/dev/null || true
                echo "Secret '$name' written to $secret_path"
              '';
          in
          lib.mkMerge [
            (lib.mkIf hasOpEntries {
              programs.onepassword-secrets = {
                enable = true;
                secrets = lib.mapAttrs (_: v: builtins.removeAttrs v [ "source" ]) opEntries;
                tokenFile = "${config.home.homeDirectory}/.config/opnix/token";
              };
            })

            (lib.mkIf (cfg.templates != { }) {
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
            })

            # Contribute secrets subcommands to hdwlinux CLI
            {
              hdwlinux.programs.hdwlinux.subcommands.secrets = {
                set-token = ./set-token.sh;
                set = secretsSetScript;
                list = secretsListScript;
              };
            }
          ];
      };
  };
}
