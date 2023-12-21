{ options, config, lib, pkgs, inputs,... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.ssh;

  knownHostsFilePath = "${config.home.homeDirectory}/.ssh/known_hosts";
  sshConfigFilePath = "${config.home.homeDirectory}/.ssh/config";
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
    home.packages = [
      (pkgs.writeShellScriptBin "update-ssh" ''
        rm -f ${sshConfigFilePath}
        ${concatStringsSep "\n" (map (i: "cat ${i} >> ${sshConfigFilePath}") cfg.includes)}
        cat ${sshConfigFile} >> ${sshConfigFilePath}
        chmod 600 ${sshConfigFilePath}

        rm -f ${knownHostsFilePath}
        ${concatStringsSep "\n" (map (i: "cat ${i} >> ${knownHostsFilePath}") cfg.knownHosts)}
        chmod 600 ${knownHostsFilePath}
      '')
    ];
  };
}
