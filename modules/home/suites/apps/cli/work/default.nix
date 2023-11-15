{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.cli.work;
in
{
  options.hdwlinux.suites.apps.cli.work = with types; {
    enable = mkBoolOpt false "Whether or not to enable cli work apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      atlas-cli.enable = true;
      aws.enable = true;
      azure.enable = true;
      evergreen.enable = true;
      kube-cli.enable = true;
      mongodb-tools.enable = true;
      structurizr-cli.enable = true;
    };

    home.shellAliases = {
      "build!" = "./build.sh";
      "run!" = "go run ./cmd/mongohoused/mongohoused.go --config ./testdata/config/inline_local/frontend-agent-backend.yaml";
      "loginaws" = "aws sso login --profile adl && eval $(aws configure export-credentials --format env)";
    };

    home.sessionVariables = {
      GOPRIVATE = "github.com/10gen";
    };
  };
}
