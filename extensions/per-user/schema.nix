# The per-user configuration surface produced by "perUser" class modules.
# This is the entire home-manager substitute: keep it small on purpose.
#
# Evaluated per (host, user) pair by eval.nix; consumed by to-nixos.nix.
{ lib, pkgs, usercfg, ... }:
let
  inherit (lib) mkOption types;
  inherit (types) attrsOf bool either lines listOf package path str submodule;

  # A file to link into the user's home, from either literal text or a path.
  fileType = submodule (
    { config, name, ... }:
    {
      options = {
        source = mkOption {
          type = types.nullOr (either path str);
          default = if config.text != null then pkgs.writeText (
            builtins.replaceStrings [ "/" ] [ "-" ] name
          ) config.text else null;
          defaultText = "a store path built from 'text'";
          description = "Path (ideally a store path) to link into the home directory.";
        };
        text = mkOption {
          type = types.nullOr lines;
          default = null;
          description = "File content; written to the store and linked.";
        };
      };
    }
  );

  serviceType = submodule (
    { ... }:
    {
      options = {
        enable = mkOption {
          type = bool;
          default = true;
          description = "Whether the service is wanted.";
        };
        description = mkOption {
          type = str;
          default = "";
          description = "Unit description.";
        };
        script = mkOption {
          type = lines;
          default = "";
          description = "ExecStart body (shell).";
        };
        path = mkOption {
          type = listOf package;
          default = [ ];
          description = "Extra PATH entries for the unit.";
        };
        environment = mkOption {
          type = attrsOf str;
          default = { };
          description = "Per-unit Environment= entries.";
        };
        wantedBy = mkOption {
          type = listOf str;
          default = [ ];
          example = [ "graphical-session.target" ];
          description = "Targets to enable the unit for.";
        };
        after = mkOption {
          type = listOf str;
          default = [ ];
        };
        before = mkOption {
          type = listOf str;
          default = [ ];
        };
        unitConfig = mkOption {
          type = attrsOf (either str (listOf str));
          default = { };
          description = "Raw [Unit] settings (ConditionUser is set automatically).";
        };
        serviceConfig = mkOption {
          type = attrsOf (either str (listOf str));
          default = { };
          description = "Raw [Service] settings.";
        };
      };
    }
  );
in
{
  # Migration measure only: let generic class blocks (and option contributions
  # not yet given perUser declarations) fall through as inert attrs instead of
  # failing evaluation. Remove in the final cleanup to make perUser strict.
  freeformType = types.lazyAttrsOf types.anything;

  options = {
    homeDirectory = mkOption {
      type = str;
      default = "/home/${usercfg.name}";
      description = "Home directory all relative paths resolve against.";
    };

    packages = mkOption {
      type = listOf package;
      default = [ ];
      apply = lib.unique;
      description = "User packages (replaces home.packages).";
    };

    files = mkOption {
      type = attrsOf fileType;
      default = { };
      description = "Files to link into the home directory (replaces xdg.configFile / home.file). Keys are paths relative to $HOME.";
    };

    env = mkOption {
      type = attrsOf str;
      default = { };
      description = ''
        Session environment variables (replaces home.sessionVariables).
        Delivered via a linked environment.d file (takes effect for the next
        login) plus systemctl --user set-environment (this session, for units
        started afterwards).
      '';
    };

    services = mkOption {
      type = attrsOf serviceType;
      default = { };
      description = "Systemd user services (replaces systemd.user.services and hm services.*).";
    };
  };
}
