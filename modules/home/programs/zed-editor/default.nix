{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  cfg = config.hdwlinux.programs.zed-editor;
in
{
  options.hdwlinux.programs.zed-editor = {
    enable = config.lib.hdwlinux.mkEnableOption "zed-editor" [
      "programming"
      "gui"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.zed-editor ];

    xdg.configFile."zed/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${flake}/modules/home/programs/zed-editor/settings.json";
  };
}
