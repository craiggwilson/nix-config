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
      pkgs.hdwlinux.code42-aat-unwrapped

      # need to replicate the buildInputs from the unwrapped package because
      # code42-aat downloads a new binary at runtime, so patchElf doesn't work.
      pkgs.curl
      pkgs.dpkg
      pkgs.libuuid
    ];
    includeClosures = true;
    privateTmp = true;
    profile = ''
      export LD_LIBRARY_PATH="/var/opt/code42-aat/lib:/var/opt/code42-aat/lib/common:/opt/code42/lib:$LD_LIBRARY_PATH" 
      cat > /tmp/code42.deployment.properties<< EOF
      DEPLOYMENT_URL=${cfg.deployment.url}
      DEPLOYMENT_POLICY_TOKEN=${cfg.deployment.policy-token}
      DEPLOYMENT_SECRET=${cfg.deployment.secret}
      PROVIDED_USERNAME=${cfg.username}
      EOF
    '';
  };

  code42-aat = (
    pkgs.writeScriptBin "code42-aat" ''
      #! ${pkgs.bash}/bin/sh

      "${fhsEnv}/bin/code42-aat-bash" -c "code42-aat $*"
    ''
  );

  code42-aat-cli = (
    pkgs.writeScriptBin "code42-aat-cli" ''
      #! ${pkgs.bash}/bin/sh

      "${fhsEnv}/bin/code42-aat-bash" -c "code42-aat-cli $*"
    ''
  );

in
{
  options.hdwlinux.services.code42-aat = {
    enable = config.lib.hdwlinux.mkEnableOption "code42-aat" "work";
    deployment = lib.mkOption {
      type = lib.types.submodule {
        options = {
          policy-token = lib.mkOption {
            type = lib.types.str;
          };
          secret = lib.mkOption {
            type = lib.types.str;
          };
          url = lib.mkOption {
            type = lib.types.str;
          };
        };
      };
    };
    username = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf cfg.enable {
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
}
