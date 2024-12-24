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
    models = lib.mkOption {
      description = "Models to load.";
      type = lib.types.listOf lib.types.str;
      default = [ "codellama:34b" ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      acceleration = "cuda"; # if lib.hdwlinux.matchTag "nvidia" config.hdwlinux.tags then "cuda" else null;
      loadModels = cfg.models;
    };
  };
}
