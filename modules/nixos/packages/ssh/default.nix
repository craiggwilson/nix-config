{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.packages.ssh;
in
{
  options.hdwlinux.packages.ssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure ssh.";
    includes = mkOpt (listOf str) [ ] (mdDoc "Options passed directly to home-manager's `programs.ssh.includes`.");
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.ssh.enable = true;
    hdwlinux.home.programs.ssh.includes = mkAliasDefinitions options.hdwlinux.packages.ssh.includes;
  };
}
