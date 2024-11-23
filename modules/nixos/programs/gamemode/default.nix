{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.gamemode;
in
{
  options.hdwlinux.programs.gamemode = {
    enable = lib.mkOption {
      description = "Whether to enable gaming.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "gaming" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    programs.gamemode = {
      enable = true;
    };
  };
}
