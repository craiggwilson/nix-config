{ options, config, lib, pkgs, inputs,... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.ssh;
in
{
  options.hdwlinux.features.ssh = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
    includes = mkOpt (listOf str) [ ] "Other files to include in the ssh config file.";
  };

  config = mkIf cfg.enable {
    home.activation = {
      sshConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD cat << EOF > ${config.home.homeDirectory}/.ssh/config
        ${concatStringsSep "\n" (map (i: "#Include ${i}") cfg.includes)}

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
        EOF
        $DRY_RUN_CMD chmod 600 ${config.home.homeDirectory}/.ssh/config
      '';
    };
  };
}
