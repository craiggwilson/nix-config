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
    enable = config.lib.hdwlinux.mkEnableOption "ollama" false; # "llm";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      acceleration = if lib.hdwlinux.matchTag "nvidia" config.hdwlinux.tags then "cuda" else null;
      loadModels = [
        "codellama:34b"
      ];
    };
  };
}
