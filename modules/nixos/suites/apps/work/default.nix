{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.work;
in
{
  options.hdwlinux.suites.apps.work = with types; {
    enable = mkBoolOpt false "Whether or not to enable work apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.suites.apps.programming.enable = true;
    
    hdwlinux.packages = {
      atlas-cli.enable = true;
      aws.enable = true;
      azure.enable = true;
      kube.enable = true;
      mongodb.enable = true;
      slack.enable = true;
      zoom-us.enable = true;
    };

    hdwlinux.home.shellAliases = {
      "build!" = "./build.sh";
    };
  };
}
