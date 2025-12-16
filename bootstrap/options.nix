# Flake-parts module that defines the project options.
# This centralizes all project.* option definitions.
{ lib, ... }:
{
  options.project = {
    lib = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      description = "The library functions for NixOS/Home Manager configurations";
    };

    # Lists of paths for overlays, packages, shells, and modules
    overlays = lib.mkOption {
      type = lib.types.listOf lib.types.unspecified;
      default = [ ];
      description = "List of overlay functions to compose";
    };

    packages = lib.mkOption {
      type = lib.types.either (lib.types.listOf lib.types.path) (
        lib.types.submodule {
          options = {
            paths = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              description = "List of package paths (each containing a default.nix)";
            };
            namespace = lib.mkOption {
              type = lib.types.str;
              description = "Namespace for packages in pkgs (e.g., 'hdwlinux' for pkgs.hdwlinux.*)";
            };
          };
        }
      );
      default = [ ];
      description = "Package paths as a list (added directly to pkgs) or an attrset with 'paths' and 'namespace'";
    };

    shells = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "List of dev shell paths (each containing a default.nix)";
    };

    nixosModules = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "List of NixOS module paths";
    };

    homeModules = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "List of Home Manager module paths";
    };

    formatter = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "nixfmt-rfc-style";
      description = "Package name for the formatter (null to disable)";
    };

    external = {
      overlays = lib.mkOption {
        type = lib.types.listOf lib.types.unspecified;
        default = [ ];
        description = "External overlays to include in all configurations";
      };

      nixosModules = lib.mkOption {
        type = lib.types.listOf lib.types.unspecified;
        default = [ ];
        description = "External NixOS modules to include in all system configurations";
      };

      homeModules = lib.mkOption {
        type = lib.types.listOf lib.types.unspecified;
        default = [ ];
        description = "External Home Manager modules to include in all home configurations";
      };
    };

    nixosSystems = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.either lib.types.path (
          lib.types.submodule {
            options = {
              path = lib.mkOption {
                type = lib.types.path;
                description = "Path to the system configuration directory";
              };
              format = lib.mkOption {
                type = lib.types.nullOr (lib.types.enum [ "install-iso" ]);
                default = null;
                description = "Special format for the system (e.g., install-iso)";
              };
              system = lib.mkOption {
                type = lib.types.str;
                default = "x86_64-linux";
                description = "System architecture";
              };
              users = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "List of usernames whose home configurations (from project.homes) to include";
              };
            };
          }
        )
      );
      default = { };
      description = "NixOS system configurations to build";
    };

    homes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.either lib.types.path (
          lib.types.submodule {
            options = {
              path = lib.mkOption {
                type = lib.types.path;
                description = "Path to the home configuration directory";
              };
              system = lib.mkOption {
                type = lib.types.str;
                default = "x86_64-linux";
                description = "System architecture";
              };
            };
          }
        )
      );
      default = { };
      description = "Home Manager configurations to build";
    };
  };
}
