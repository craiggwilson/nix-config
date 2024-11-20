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
    enable = lib.hdwlinux.mkBoolOpt true "Whether to enable dconf.";
  };

  config = lib.mkIf cfg.enable {
    programs.dconf.enable = true;
  };
}
