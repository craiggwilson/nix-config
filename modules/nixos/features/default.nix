{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features;
in
{
  options.hdwlinux.features = with types; {
    tags = mkOpt (listOf str) [] "The tags for features enablement.";
  };
}
