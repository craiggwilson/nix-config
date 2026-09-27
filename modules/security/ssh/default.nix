{
  config.substrate.modules.security.ssh = {
    perUser =
      { config, lib, pkgs, ... }:
      let
        cfg = config.hdwlinux.security.ssh;

        toDirective =
          v:
          if lib.isBool v then
            (if v then "yes" else "no")
          else
            toString v;

        renderHost =
          name: opts:
          "Host ${name}\n" + lib.concatStrings (lib.mapAttrsToList (k: v: "  ${k} ${toDirective v}\n") opts);

        hostBlocks =
          let
            regular = lib.filter (h: h != "*") (builtins.attrNames cfg.settings);
          in
          lib.concatMapStringsSep "\n" (h: renderHost h cfg.settings.${h}) regular
          + lib.optionalString (cfg.settings ? "*") (
            lib.optionalString (regular != [ ]) "\n" + renderHost "*" cfg.settings."*"
          );
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
          hdwlinux.security.ssh.settings = {
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
          };

          # renderHost already terminates the final directive line.
          files.".ssh/config".text = hostBlocks;

          services.ssh-agent = {
            description = "SSH authentication agent";
            wantedBy = [ "default.target" ];
            unitConfig.Documentation = "man:ssh-agent(1)";
            serviceConfig.ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent";
            serviceConfig.SuccessExitStatus = "2";
          };

          # Publishes SSH_AUTH_SOCK into the systemd/dbus user environment
          # (replaces hm services.ssh-agent's companion unit).
          services.set-SSH_AUTH_SOCK = {
            description = "Sets SSH_AUTH_SOCK in the D-BUS daemon and systemd";
            wantedBy = [
              "default.target"
              "ssh-agent.service"
            ];
            before = [ "ssh-agent.service" ];
            path = [ pkgs.dbus ];
            script = ''
              if [[ -z "''${SSH_AUTH_SOCK:-}" ]]; then
                export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
              fi
              dbus-update-activation-environment --systemd SSH_AUTH_SOCK
            '';
            serviceConfig.Type = "oneshot";
          };
        };
      };
  };
}
