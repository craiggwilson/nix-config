{
  config.substrate.modules.services.osquery = {
    tags = [ "users:craig:work" ];

    nixos =
      { config, lib, pkgs, ... }:
      let
        cfg = config.hdwlinux.services.osquery;
        dirname =
          path:
          with lib.strings;
          with lib.lists;
          concatStringsSep "/" (init (splitString "/" (normalizePath path)));

        conf = pkgs.writeText "osquery.conf" (builtins.toJSON cfg.settings);

        flagfile = pkgs.writeText "osquery.flags" (
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: value: "--${name}=${value}")
              ({ config_path = conf; } // cfg.flags)
          )
        );

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
          settings = lib.mkOption {
            default = { };
            description = "Configuration to be written to the osqueryd JSON configuration file.";
            type = lib.types.attrs;
          };

          flags-cli = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Attribute set of flag names and values to be applied on the command line.";
          };

          flags = lib.mkOption {
            default = { };
            description = "Attribute set of flag names and values to be written to the osqueryd flagfile.";
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

        config = {
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
      };
  };
}

