{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.calibre;
in
{
  options.hdwlinux.programs.calibre = {
    enable = config.lib.hdwlinux.mkEnableOption "calibre" [
      "gui"
      "personal"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.stable.calibre.overrideAttrs (old: {
        buildInputs = old.buildInputs ++ [ pkgs.makeWrapper ];
        postInstall = old.postInstall or "" + ''
          wrapProgram "$out/bin/calibre" --set CALIBRE_USE_SYSTEM_THEME 1
        '';
      }))
    ];
  };
}
