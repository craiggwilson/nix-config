{ lib, ... }:
{
  config.substrate.modules.security.ssh = {
    tags = [ ]; # Always included

    homeManager =
      { config, lib, ... }:
      let
        cfg = config.hdwlinux.security.ssh;
      in
      {
        options.hdwlinux.security.ssh = {
          knownHosts = lib.mkOption {
            type = lib.types.listOf lib.types.path;
            default = [ ];
            description = "Known hosts to include in the known hosts file.";
          };
          matchBlocks = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "SSH host configurations that get applied to programs.ssh.matchBlocks.";
          };
        };

        config = {
          programs.ssh = {
            enable = true;
            enableDefaultConfig = false;
            matchBlocks = lib.mkMerge [
              {
                "*" = {
                  addKeysToAgent = "yes";
                  compression = true;
                  forwardAgent = false;
                  serverAliveInterval = 0;
                  serverAliveCountMax = 3;
                  hashKnownHosts = false;
                  controlMaster = "no";
                  controlPath = "~/.ssh/master-%r@%n:%p";
                  controlPersist = "no";
                  userKnownHostsFile = "~/.ssh/known_hosts " + (lib.concatStringsSep " " cfg.knownHosts);
                };
              }
              cfg.matchBlocks
            ];
          };
        };
      };
  };
}

