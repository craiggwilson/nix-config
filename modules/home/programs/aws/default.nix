{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.aws-cli;
in
{
  options.hdwlinux.programs.aws-cli = {
    enable = config.lib.hdwlinux.mkEnableOption "aws-cli" [
      "programming"
      "work"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.awscli2 ];
  };
}
