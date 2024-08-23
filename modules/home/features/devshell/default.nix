{
  options,
  config,
  lib,
  pkgs,
  flake,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.devshell;
in
{
  options.hdwlinux.features.devshell = with types; {
    enable = mkEnableOpt [ "programming" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (writeShellScriptBin "devshell" ''
        name="$1";
        shift;
        nix develop ${flake}#$name $@;
      '')
    ];
  };
}
