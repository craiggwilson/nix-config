{
  config.substrate.modules.services.code42-aat = {
    tags = [ "users:craig:work" ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.services.code42-aat;

        fhsEnv = pkgs.buildFHSEnv {
          name = "code42-aat-bash";
          targetPkgs = pkgs: [
            pkgs.hdwlinux.code42-aat
            pkgs.curl
            pkgs.dpkg
            pkgs.libuuid
          ];
          includeClosures = true;
          privateTmp = true;
          profile = ''
            export LD_LIBRARY_PATH="/var/opt/code42-aat/lib:/var/opt/code42-aat/lib/common:/opt/code42/lib:/usr/lib:$LD_LIBRARY_PATH" 
            cat > /tmp/code42.deployment.properties<< EOF
            DEPLOYMENT_URL=${cfg.deployment.url}
            DEPLOYMENT_POLICY_TOKEN=$(cat ${cfg.deployment.policyTokenFile})
            DEPLOYMENT_SECRET=$(cat ${cfg.deployment.secretFile})
            PROVIDED_USERNAME=${cfg.username}
            EOF
          '';
        };

        code42-aat = pkgs.writeScriptBin "code42-aat" ''
          #! ${pkgs.bash}/bin/sh
          "${fhsEnv}/bin/code42-aat-bash" -c "code42-aat $*"
        '';

        code42-aat-cli = pkgs.writeScriptBin "code42-aat-cli" ''
          #! ${pkgs.bash}/bin/sh
          "${fhsEnv}/bin/code42-aat-bash" -c "code42-aat-cli $*"
        '';
      in
      {
        options.hdwlinux.services.code42-aat = {
          deployment = lib.mkOption {
            type = lib.types.submodule {
              options = {
                policyTokenFile = lib.mkOption {
                  type = lib.types.str;
                  description = "Path to file containing the policy token.";
                };
                secretFile = lib.mkOption {
                  type = lib.types.str;
                  description = "Path to file containing the deployment secret.";
                };
                url = lib.mkOption {
                  type = lib.types.str;
                  description = "Deployment URL.";
                };
              };
            };
            description = "Deployment configuration for Code42 AAT.";
          };
          username = lib.mkOption {
            type = lib.types.str;
            description = "Username for Code42 AAT.";
          };
        };

        config = {
          environment.systemPackages = [
            code42-aat
            code42-aat-cli
          ];

          systemd.services.code42-aat = {
            enable = true;
            description = "Code42-AAT";
            serviceConfig = {
              ExecStart = "${code42-aat}/bin/code42-aat";
              Restart = "always";
              RestartSec = 10;
              SyslogIdentifier = "code42-aat";
              KillMode = "process";
            };
            wantedBy = [ "multi-user.target" ];
          };
        };
      };
  };
}
