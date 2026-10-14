{
  config.substrate.modules.ai.clients.tasks.opencode = {
    tags = [ "ai:clients" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        tasks = config.hdwlinux.ai.clients.tasks;

        # Resolve an alias to its primary "provider/model" string for opencode's --model flag.
        resolveAlias =
          aliasName:
          let
            primary = lib.head config.hdwlinux.ai.clients.models.aliases.${aliasName}.models;
          in
          "${primary.provider}/${primary.model}";

        taskConfig =
          name: task:
          let
            serviceName = "ai-task-${name}";
            promptFile = "${config.home.homeDirectory}/.config/opencode/prompts/tasks/${name}.md";
            flags = lib.concatStringsSep " " (
              lib.optional (task.agent != null) "--agent ${lib.escapeShellArg task.agent}"
              ++ lib.optionals (task.model != null) [
                "--model"
                (lib.escapeShellArg (resolveAlias task.model))
              ]
              ++ lib.optional task.continueSession "--continue"
              ++ lib.optional task.autoApprove "--auto"
            );
            execStart = pkgs.writeShellScript serviceName ''
              # Unattended runs need the agent's tools on PATH; the user manager
              # starts with a minimal environment.
              PATH="${
                lib.makeBinPath [
                  pkgs.coreutils
                  pkgs.git
                  pkgs.jujutsu
                ]
              }:$PATH"
              exec ${lib.getExe config.programs.opencode.package} run ${flags} "$(cat ${lib.escapeShellArg promptFile})"
            '';
          in
          {
            services.${serviceName} = {
              Unit.Description = task.description;
              Service = {
                Type = "oneshot";
                ExecStart = execStart;
                RuntimeMaxSec = task.timeout;
                WorkingDirectory = task.workingDirectory;
              };
            };

            timers.${serviceName} = {
              Unit.Description = task.description;
              Timer = {
                OnCalendar = task.schedule;
                Persistent = true;
              };
              Install.WantedBy = [ "timers.target" ];
            };
          };
      in
      {
        xdg.configFile = lib.mapAttrs' (
          name: task: lib.nameValuePair "opencode/prompts/tasks/${name}.md" { source = task.prompt; }
        ) tasks;

        systemd.user = lib.mkMerge (lib.mapAttrsToList taskConfig tasks);
      };
  };
}
