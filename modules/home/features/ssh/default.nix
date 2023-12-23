{ options, config, lib, pkgs, inputs,... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.ssh;

  sshConfigFile = pkgs.writeText "ssh_config" ''
    # Default
    Host *
      ForwardAgent no
      Compression no
      ServerAliveInterval 0
      ServerAliveCountMax 3
      HashKnownHosts no
      UserKnownHostsFile ~/.ssh/known_hosts
      ControlMaster no
      ControlPath ~/.ssh/master-%r@%n:%p
      ControlPersist no
  '';
in
{
  options.hdwlinux.features.ssh = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
    includes = mkOpt (listOf path) [ ] "Other files to include in the ssh config file.";
    knownHosts = mkOpt (listOf path) [ ] "Known hosts to include in the known hosts file.";
  };

  config = mkIf cfg.enable {
    hdwlinux.user.updates.ssh = {
      config = lib.hdwlinux.withConfirmOverwrite "${config.home.homeDirectory}/.ssh/config" ''
        rm -f $out
        ${concatStringsSep "\n" (map (i: "cat ${i} >> $out") cfg.includes)}
        cat ${sshConfigFile} >> $out
        chmod 600 $out
      '';
      known-hosts = lib.hdwlinux.withConfirmOverwrite "${config.home.homeDirectory}/.ssh/known_hosts" '' 
        rm -f $out
        ${concatStringsSep "\n" (map (i: "cat ${i} >> $out") cfg.knownHosts)}
        chmod 600 $out
      '';
    };
  };
}
