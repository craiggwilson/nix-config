{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.services.ollama;
in
{

  options.hdwlinux.services.ollama = {
    enable = config.lib.hdwlinux.mkEnableOption "ollama" [
      "llm"
    ];
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
    };

    home.packages = [ pkgs.gollama ];
  };
}
