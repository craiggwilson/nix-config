{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.micro;
in
{
  options.hdwlinux.programs.micro = {
    enable = lib.hdwlinux.mkEnableOption "micro" true;
  };

  config = lib.mkIf cfg.enable {
    programs.micro = {
      enable = true;
      settings = {
        mkparents = true;
        softwrap = true;
      };
    };

    home.sessionVariables = {
      EDITOR = "micro";
      VISUAL = "micro";
    };
  };
}
