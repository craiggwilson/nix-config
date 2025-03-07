# This is a copy of the osquery module from the NixOS repository. I needed to add the flagscli attribute to the configuration
# to render certain flags on the cli for reasons.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.services.osquery;
  dirname =
    path:
    with lib.strings;
    with lib.lists;
    concatStringsSep "/" (init (splitString "/" (normalizePath path)));

  # conf is the osquery configuration file used when the --config_plugin=filesystem.
  # filesystem is the osquery default value for the config_plugin flag.
  conf = pkgs.writeText "osquery.conf" (builtins.toJSON cfg.settings);

  # flagfile is the file containing osquery command line flags to be
  # provided to the application using the special --flagfile option.
  flagfile = pkgs.writeText "osquery.flags" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "--${name}=${value}")
        # Use the conf derivation if not otherwise specified.
        ({ config_path = conf; } // cfg.flags)
    )
  );

  # flags is the command line flags to be provided to osqueryd and osqueryi.
  flags = lib.concatStringsSep " " (
    lib.mapAttrsToList (name: value: "--${name}=${value}") cfg.flags-cli
  );

  osqueryi = pkgs.runCommand "osqueryi" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/bin
    makeWrapper ${pkgs.osquery}/bin/osqueryi $out/bin/osqueryi \
      --add-flags "--flagfile ${flagfile} --disable-database ${flags}"
  '';
in
{
  options.hdwlinux.services.osquery = {
    enable = config.lib.hdwlinux.mkEnableOption "osquery" "work";
    settings = lib.mkOption {
      default = { };
      description = ''
        Configuration to be written to the osqueryd JSON configuration file.
        To understand the configuration format, refer to https://osquery.readthedocs.io/en/stable/deployment/configuration/#configuration-components.
      '';
      example = {
        options.utc = false;
      };
      type = lib.types.attrs;
    };

    flags-cli = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = ''
        Attribute set of flag names and values to be applied on the command line.
        For more information, refer to https://osquery.readthedocs.io/en/stable/installation/cli-flags.
      '';
    };

    flags = lib.mkOption {
      default = { };
      description = ''
        Attribute set of flag names and values to be written to the osqueryd flagfile.
        For more information, refer to https://osquery.readthedocs.io/en/stable/installation/cli-flags.
      '';
      example = {
        config_refresh = "10";
      };
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.str;
        options = {
          database_path = lib.mkOption {
            default = "/var/lib/osquery/osquery.db";
            readOnly = true;
            description = "Path used for the database file.";
            type = lib.types.path;
          };
          logger_path = lib.mkOption {
            default = "/var/log/osquery";
            readOnly = true;
            description = "Base directory used for logging.";
            type = lib.types.path;
          };
          pidfile = lib.mkOption {
            default = "/run/osquery/osqueryd.pid";
            readOnly = true;
            description = "Path used for pid file.";
            type = lib.types.path;
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ osqueryi ];
    systemd.services.osqueryd = {
      after = [
        "network.target"
        "syslog.service"
      ];
      description = "The osquery daemon";
      serviceConfig = {
        ExecStart = "${pkgs.osquery}/bin/osqueryd --flagfile ${flagfile} ${flags}";
        PIDFile = cfg.flags.pidfile;
        LogsDirectory = cfg.flags.logger_path;
        StateDirectory = dirname cfg.flags.database_path;
        Restart = "always";
      };
      wantedBy = [ "multi-user.target" ];
    };
    systemd.tmpfiles.settings."10-osquery".${dirname (cfg.flags.pidfile)}.d = {
      user = "root";
      group = "root";
      mode = "0755";
    };
  };
}
