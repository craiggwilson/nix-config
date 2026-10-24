{
  config.substrate.modules.ai.clients.tasks = {
    tags = [ "profile:ai" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        wrap,
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
            # systemd WorkingDirectory= requires an absolute path and does not
            # expand "~", so resolve a leading "~" to the home directory here.
            workingDirectory =
              if lib.hasPrefix "~" task.workingDirectory then
                config.home.homeDirectory + lib.removePrefix "~" task.workingDirectory
              else
                task.workingDirectory;
            flags = lib.concatStringsSep " " (
              lib.optional (task.agent != null) "--agent ${lib.escapeShellArg task.agent}"
              ++ lib.optionals (task.model != null) [
                "--model"
                (lib.escapeShellArg (resolveAlias task.model))
              ]
              ++ lib.optional task.continueSession "--continue"
              ++ lib.optional task.autoApprove "--auto"
            );
            # Values are written verbatim so they can reference secrets injected
            # at exec time (e.g. GH_TOKEN="$GITHUB_API_TOKEN").
            exports = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (k: v: ''export ${k}="${v}"'') task.environment
            );
            scriptBin = pkgs.writeShellScriptBin serviceName ''
              # Unattended runs need the agent's tools on PATH; the user manager
              # starts with a minimal environment.
              PATH="${
                lib.makeBinPath (
                  [
                    pkgs.coreutils
                    pkgs.git
                    pkgs.jujutsu
                  ]
                  ++ task.packages
                )
              }:$PATH"
              ${exports}
              exec ${lib.getExe config.programs.opencode.package} run ${flags} "$(cat ${lib.escapeShellArg promptFile})"
            '';
            # When a secrets scope is set, wrap the script so secretspec resolves
            # that scope and injects its values into the environment at exec time.
            execStart = lib.getExe (
              if task.secretsScope == null then
                scriptBin
              else
                wrap.package {
                  package = scriptBin;
                  secrets.scope = task.secretsScope;
                }
            );
          in
          {
            services.${serviceName} = {
              Unit = {
                Description = task.description;
                After = map (taskName: "ai-task-${taskName}.service") task.after;
              };
              Service = {
                Type = "oneshot";
                ExecStart = execStart;
                # oneshot services bound their runtime with TimeoutStartSec;
                # RuntimeMaxSec is ignored for Type=oneshot.
                TimeoutStartSec = task.timeout;
                WorkingDirectory = workingDirectory;
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
