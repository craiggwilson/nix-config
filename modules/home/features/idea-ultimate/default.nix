{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.features.idea-community;
in
{
  options.hdwlinux.features.idea-community = {
    enable = lib.hdwlinux.mkEnableOpt [
      "gui"
      "programming"
    ] config.hdwlinux.features.tags;
  };

  config.home.packages = lib.mkIf cfg.enable [
    pkgs.jetbrains.idea-ultimate
    (pkgs.writeShellScriptBin "idea" ''
      nohup ${pkgs.stable.jetbrains.idea-ultimate}/bin/idea-ultimate "$@" </dev/null >/dev/null 2>&1 &
      disown
    '')
  ];
}
