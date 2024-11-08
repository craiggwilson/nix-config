{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.kube-cli;
in
{
  options.hdwlinux.features.kube-cli = {
    enable = lib.hdwlinux.mkEnableOpt [
      "work"
    ] config.hdwlinux.features.tags;
    enableAliases = lib.hdwlinux.mkBoolOpt true "Whether or not to enable aliases.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      kubectl
      kubectx
    ];

    home.shellAliases = lib.mkIf cfg.enableAliases {
      k = "kubectl";
      kctx = "kubectx";
      kns = "kubens";
    };
  };
}
