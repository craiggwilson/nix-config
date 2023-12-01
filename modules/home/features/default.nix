{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features;
  elemsAll = x: xs: builtins.all (e: builtins.elem e xs) x;
in
{
  options.hdwlinux.features = with types; {
    tags = mkOpt (listOf str) [] "The tags for features enablement.";
  };
}
