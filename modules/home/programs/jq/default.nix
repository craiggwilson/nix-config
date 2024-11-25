{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.jq;
in
{
  options.hdwlinux.programs.jq = {
    enable = lib.hdwlinux.mkEnableOption "jq" true;
  };

  config = lib.mkIf cfg.enable {
    programs.jq = {
      enable = true;
    };
  };
}
