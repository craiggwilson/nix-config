{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.appimage;
in
{
  options.hdwlinux.programs.appimage = {
    enable = lib.hdwlinux.mkEnableOption "appimage" true;
  };

  config = lib.mkIf cfg.enable {
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
