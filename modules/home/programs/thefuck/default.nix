{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.thefuck;
in
{
  options.hdwlinux.programs.thefuck = {
    enable = lib.hdwlinux.mkEnableOption "thefuck" true;
  };

  config = lib.mkIf cfg.enable {
    programs.thefuck = {
      enable = true;
      enableInstantMode = false;
      enableBashIntegration = config.hdwlinux.programs.bash.enable;
      enableZshIntegration = config.hdwlinux.programs.zsh.enable;
    };
  };
}
