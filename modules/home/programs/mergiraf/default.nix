{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.mergiraf;
in
{
  options.hdwlinux.programs.mergiraf = {
    enable = lib.hdwlinux.mkEnableOption "mergiraf" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mergiraf ];

    programs.git = {
      extraConfig = lib.mkIf config.hdwlinux.programs.git.enable {
        "merge \"mergiraf\"" = {
          name = "mergiraf";
          driver = "${pkgs.mergiraf}/bin/mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P";
        };
      };
      attributes = [
        "*.java merge=mergiraf"
        "*.rs merge=mergiraf"
        "*.go merge=mergiraf"
        "*.js merge=mergiraf"
        "*.jsx merge=mergiraf"
        "*.json merge=mergiraf"
        "*.yml merge=mergiraf"
        "*.yaml merge=mergiraf"
        "*.toml merge=mergiraf"
        "*.html merge=mergiraf"
        "*.htm merge=mergiraf"
        "*.xhtml merge=mergiraf"
        "*.xml merge=mergiraf"
        "*.c merge=mergiraf"
        "*.cc merge=mergiraf"
        "*.h merge=mergiraf"
        "*.cpp merge=mergiraf"
        "*.hpp merge=mergiraf"
        "*.cs merge=mergiraf"
        "*.dart merge=mergiraf"
        "*.scala merge=mergiraf"
        "*.sbt merge=mergiraf"
        "*.ts merge=mergiraf"
        "*.py merge=mergiraf"
      ];
    };
  };
}
