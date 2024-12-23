{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.gpt4all;
in
{
  options.hdwlinux.programs.gpt4all = {
    enable = config.lib.hdwlinux.mkEnableOption "gpt4all" [
      "gui"
      "llm"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gpt4all-cuda ];
  };
}
