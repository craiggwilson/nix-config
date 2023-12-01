{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.ssh;
in
{
  options.hdwlinux.features.ssh = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
    includes = mkOpt (listOf str) [ ] (mdDoc "Options passed directly to home-manager's `programs.ssh.includes`.");
  };

  config.programs.ssh = mkIf cfg.enable {
    enable = true;
    includes = mkAliasDefinitions options.hdwlinux.features.ssh.includes;
  };
}
