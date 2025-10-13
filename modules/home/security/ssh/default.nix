{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.security.ssh;
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

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = map (i: "${i}") cfg.includes;

      matchBlocks."*" = {
        addKeysToAgent = "yes";
        compression = true;
        userKnownHostsFile = "~/.ssh/known_hosts " + (lib.concatStringsSep " " cfg.knownHosts);
        forwardAgent = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
    };
  };
}
