{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.dconf;
in
{
  options.hdwlinux.programs.dconf = {
    enable = lib.mkOption {
      description = "Whether to enable dconf.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.dconf.enable = true;
  };
}
