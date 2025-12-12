{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.raeford.outputProfiles;
in
{
  options.hdwlinux.raeford.outputProfiles = {
    enable = config.lib.hdwlinux.mkEnableOption "raeford office output profiles" "raeford";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.outputProfiles = {
      raeford-docked = {
        outputs = [
          {
            monitor = "office-main";
            enable = true;
            position = "0,1440";
            workspaces = [ "3" ];
          }
          {
            monitor = "office-top";
            enable = true;
            position = "1290,0";
            workspaces = [ "1" ];
          }
          {
            monitor = "portable";
            enable = true;
            position = "1000,2880";
            workspaces = [ "2" ];
          }
          {
            monitor = "laptop";
            enable = false;
          }
        ];
      };
    };
  };
}
