{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.home-manager;
in
{
  options.hdwlinux.home-manager = {
    enable = lib.hdwlinux.mkEnableOption "home-manager" true;
  };

  config = {
    programs.home-manager.enable = cfg.enable;

    lib.file.mkOutOfStoreSymlink =
      path:
      let
        pathStr = toString path;
        name = inputs.home-manager.lib.hm.strings.storeFileName (baseNameOf pathStr);
      in
      pkgs.runCommandLocal name { } "ln -s ${lib.escapeShellArg pathStr} $out";
  };
}
