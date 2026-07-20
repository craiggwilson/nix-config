{
  config.substrate.modules.security.ssh = {
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
          settings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "SSH host configurations in OpenSSH directive format. Attr names become Host patterns.";
          };
        };

        config = {
          services.ssh-agent.enable = true;

          programs.ssh = {
            enable = true;
            enableDefaultConfig = false;
            settings = lib.mkMerge [
              {
                "*" = {
                  AddKeysToAgent = "yes";
                  Compression = true;
                  ForwardAgent = false;
                  ServerAliveInterval = 0;
                  ServerAliveCountMax = 3;
                  HashKnownHosts = false;
                  ControlMaster = "no";
                  ControlPath = "~/.ssh/master-%r@%n:%p";
                  ControlPersist = "no";
                  UserKnownHostsFile = "~/.ssh/known_hosts " + (lib.concatStringsSep " " cfg.knownHosts);
                };
              }
              cfg.settings
            ];
          };
        };
      };
  };
}
