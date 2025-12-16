{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.zsh;
in
{
  options.hdwlinux.programs.zsh = {
    enable = lib.hdwlinux.mkEnableOption "zsh" true;
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
    };

    users.defaultUserShell = pkgs.zsh;
  };
}
