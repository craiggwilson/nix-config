{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.ollama;
in
{
  options.hdwlinux.services.ollama = {
    enable = config.lib.hdwlinux.mkEnableOption "ollama" "llm";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      acceleration = if lib.hdwlinux.matchTag "nvidia" config.hdwlinux.tags then "cuda" else null;
    };
  };
}
