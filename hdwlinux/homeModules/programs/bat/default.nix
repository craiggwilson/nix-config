{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.bat;
in
{
  options.hdwlinux.programs.bat = {
    enable = lib.hdwlinux.mkEnableOption "bat" true;
  };

  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config = {
        theme = "base16";
      };
    };
  };
}
