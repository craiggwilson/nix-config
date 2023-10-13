{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.theme; 
in {
  options.hdwlinux.theme = with types; {
    color1 = mkStrOpt "" "The base color.";
    color2 = mkStrOpt "" "The next color.";
  };
}
