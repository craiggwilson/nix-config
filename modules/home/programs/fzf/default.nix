{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.fzf;
in
{
  options.hdwlinux.programs.fzf = {
    enable = lib.hdwlinux.mkEnableOption "fzf" true;
  };

  config = lib.mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableBashIntegration = config.hdwlinux.programs.bash.enable;
    };
  };
}
