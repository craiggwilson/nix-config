{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.security.ssh;

  sshConfigFile = pkgs.writeText "ssh_config" ''
    Host *
      ForwardAgent no
      Compression yes
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
  options.hdwlinux.security.ssh = {
    enable = lib.hdwlinux.mkEnableOption "ssh" true;
    includes = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Other files to include in the ssh config file.";
    };
    knownHosts = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Known hosts to include in the known hosts file.";
    };
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.user.updates.ssh = {
      config = lib.hdwlinux.file.withConfirmOverwrite "${config.home.homeDirectory}/.ssh/config" ''
        rm -f $out
        ${lib.concatStringsSep "\n" (map (i: "cat ${i} >> $out") cfg.includes)}
        cat ${sshConfigFile} >> $out
        chmod 600 $out
      '';
      known-hosts = lib.hdwlinux.file.withConfirmOverwrite "${config.home.homeDirectory}/.ssh/known_hosts" ''
        rm -f $out
        ${lib.concatStringsSep "\n" (map (i: "cat ${i} >> $out") cfg.knownHosts)}
        chmod 600 $out
      '';
    };
  };
}
