{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.kube-cli;
in
{
  options.hdwlinux.features.kube-cli = with types; {
    enable = mkEnableOpt ["cli" "programming" "work"] config.hdwlinux.features.tags;
    enableAliases = mkBoolOpt true "Whether or not to enable aliases.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ 
        kubectl
        kubectx
    ];

    home.shellAliases = mkIf cfg.enableAliases {
      k = "kubectl";
      kctx = "kubectx";
      kns = "kubens";
    };
  };
}
