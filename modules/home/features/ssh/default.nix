{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.ssh;
in
{
  options.hdwlinux.features.ssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure ssh.";
    includes = mkOpt (listOf str) [ ] (mdDoc "Options passed directly to home-manager's `programs.ssh.includes`.");
  };

  config.programs.ssh = mkIf cfg.enable {
    enable = true;
    includes = mkAliasDefinitions options.hdwlinux.features.ssh.includes;
  };
}
