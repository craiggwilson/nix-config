{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.kube;
in
{
  options.hdwlinux.packages.kube = with types; {
    enable = mkBoolOpt false "Whether or not to enable kubectl and kubectx.";
    enableAliases = mkBoolOpt true "Whether or not to enable aliases.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        kubectl
        kubectx
    ];

    hdwlinux.home.shellAliases = mkIf cfg.enableAliases {
      k = "kubectl";
      kctx = "kubectx";
      kns = "kubens";
    };
  };
}
