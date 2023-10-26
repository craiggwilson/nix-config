{ inputs, options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.home-manager;
in
{
  options.hdwlinux.features.home-manager = with types; {
    enable = mkBoolOpt true "Whether or not to enable home-manager.";
  };

  config = {
    programs.home-manager.enable = cfg.enable;

    lib.file.mkOutOfStoreSymlink = path: 
      let
        pathStr = toString path;
        name = inputs.home-manager.lib.hm.strings.storeFileName (baseNameOf pathStr);
      in
        pkgs.runCommandLocal name {} ''ln -s ${lib.escapeShellArg pathStr} $out'';
  };
}
