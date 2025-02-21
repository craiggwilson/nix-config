{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.lmstudio;
in
{
  options.hdwlinux.programs.lmstudio = {
    enable = config.lib.hdwlinux.mkEnableOption "lmstudio" [
      "gui"
      "llm"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.lmstudio ];
  };
}
