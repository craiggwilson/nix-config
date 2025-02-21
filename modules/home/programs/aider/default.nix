{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.aider;
in
{
  options.hdwlinux.programs.aider = {
    enable = config.lib.hdwlinux.mkEnableOption "aider" [
      "llm"
      "programming"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.aider-chat ];
  };
}
