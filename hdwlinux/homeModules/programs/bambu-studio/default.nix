{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.bambu-studio;
in
{
  options.hdwlinux.programs.bambu-studio = {
    enable = config.lib.hdwlinux.mkEnableOption "bambu-studio" "personal";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.bambu-studio ];
  };
}
