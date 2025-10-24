{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.kube-cli;
in
{
  options.hdwlinux.programs.kube-cli = {
    enable = config.lib.hdwlinux.mkEnableOption "kube-cli" "work";
    enableAliases = lib.hdwlinux.mkEnableOption "aliases" true;
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
