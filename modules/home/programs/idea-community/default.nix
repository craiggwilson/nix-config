{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.idea-community;
in
{
  options.hdwlinux.programs.idea-community = {
    enable = config.lib.hdwlinux.mkEnableOption "idea-community" [
      "gui"
      "programming"
      "work"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.jetbrains.idea-ultimate
      (pkgs.writeShellScriptBin "idea" ''
        nohup ${pkgs.jetbrains.idea-ultimate}/bin/idea-ultimate "$@" </dev/null >/dev/null 2>&1 &
        disown
      '')
    ];
  };
}
