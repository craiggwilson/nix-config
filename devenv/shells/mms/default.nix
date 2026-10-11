{
  substrate.devenv.shells.mms =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      javapkg = pkgs.temurin-bin-17;

      # Bazel's built-in CopyFile action runs `<shell> -c 'cp ...'` with `exec env -`,
      # stripping all environment variables. --action_env and BASH_ENV are both ignored
      # by this built-in. The fix is to point --shell_executable at a wrapper that
      # unconditionally sets PATH to include standard Unix tools before exec'ing real bash.
      bazelShellWrapper = pkgs.writeShellScript "bazel-shell" ''
        export PATH=${pkgs.coreutils}/bin:${pkgs.bash}/bin:${pkgs.findutils}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.gnused}/bin:${pkgs.gawk}/bin:${pkgs.unzip}/bin:${pkgs.zip}/bin:${pkgs.which}/bin:${pkgs.gnugrep}/bin:${pkgs.python3}/bin''${PATH:+:$PATH}
        exec ${pkgs.bash}/bin/bash "$@"
      '';

      opensshPatched = pkgs.openssh.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./openssh.patch ];
        doCheck = false;
      });
    in
    {
      # A work shell: the toolchain is only useful inside the mms checkout, so
      # enterShell warns when it is missing. Under an impure evaluation the root
      # follows you into the checkout you opened the shell from, which is what
      # puts `.devenv` next to the code; under a pure one it falls back to $HOME,
      # because devenv creates `<root>/.devenv` eagerly and pointing it at an
      # absent checkout would build the tree.
      devenv.root =
        let
          pwd = builtins.getEnv "PWD";
        in
        if pwd != "" then pwd else "/home/craig";

      packages = [
        # Bazel
        pkgs.bazelisk
        pkgs.gcc
        pkgs.glibc
        pkgs.hdwlinux.engflow_auth
        pkgs.libz
        pkgs.bazel-buildtools

        # Java
        javapkg
        pkgs.google-java-format

        # Go
        pkgs.go

        # node
        pkgs.nodejs_22
        pkgs.pnpm

        # python
        pkgs.openblas
        pkgs.python3.pkgs.python
        pkgs.python3.pkgs.venvShellHook

        # fern
        pkgs.hdwlinux.fern
        pkgs.minikube
        pkgs.tilt

        # other
        pkgs.amazon-ecr-credential-helper
        pkgs.buf
        pkgs.dyff
        pkgs.graphviz
        pkgs.just
        pkgs.kubernetes-helm
        pkgs.libxml2
        pkgs.pre-commit
        pkgs.openssl
        opensshPatched
        pkgs.yq
        pkgs.zip

        pkgs.cairo
        pkgs.giflib
        pkgs.libjpeg
        pkgs.libpng
        pkgs.librsvg
        pkgs.pango

        # devenv-tasks runs tasks and drives the non-native process manager.
        # It is exposed as config.task.package rather than coming from a devenv
        # flake input, which keeps the lock file unchanged.
        config.task.package
      ];

      # The default is already process-compose in flake mode (no devenv CLI to
      # provide the native manager), but stating it keeps `up` working if that
      # default ever shifts.
      process.manager.implementation = "process-compose";

      processes.mongod = {
        exec = "exec $MMS_HOME/scripts/mongodb-start-standalone.bash";
        ready.http.get.port = 27017;
      };

      scripts = {
        bazel.exec = "exec bazelisk \"$@\"";

        start-mongod-for-test.exec = ''exec "$MMS_HOME"/scripts/mongodb-start-standalone.bash -p 26000'';

        # procfileScript is devenv's `devenv-up`: it runs the manager in the
        # foreground and traps SIGINT/SIGTERM for a clean shutdown.
        up.exec = "exec ${config.procfileScript}/bin/devenv-up";

        # `devenv tasks run` is CLI-only; devenv-tasks is not, and the paths it
        # needs are already exported by devenv.
        tasks.exec = ''
          exec devenv-tasks run \
            --task-file "$DEVENV_TASK_FILE" \
            --cache-dir "$DEVENV_DOTFILE" \
            --runtime-dir "$DEVENV_RUNTIME" \
            --mode all "$@"
        '';
      };

      env = {
        # glibc is deliberately absent. Putting one here overrides the libc
        # devenv's own devenv-tasks is built against, and a mismatched libc
        # fails at load with "__pointer_chk_guard, version GLIBC_PRIVATE".
        AWS_PROFILE = "mms-scratch";
        BAZEL_SKIP_ENGFLOW_CERT_CHECK = 1;
        BAZEL_TELEMETRY = 0;
        FERN_BASE_DIRECTORY = "$XDG_DATA_HOME/fern";
        GOPRIVATE = "github.com/10gen";
        JAVA_HOME = javapkg.home;
        LD_LIBRARY_PATH = lib.makeLibraryPath [
          pkgs.libz
          pkgs.openssl
        ];
        venvDir = "./.venv";
      };

      enterShell = ''
            export MMS_HOME="$PWD"
            mkdir -p "$TMPDIR"

            # Bazel's built-in CopyFile action runs `exec env -` stripping all env vars;
            # --action_env and BASH_ENV are both ignored by it. We fix this by pointing
            # --shell_executable at a wrapper that unconditionally sets coreutils on PATH.
            # Rewrite .bazelrc.local with the current nix store path (changes on rebuild).
            # NOTE: `nix print-dev-env` does not run enterShell, so a direnv-driven reload
            # after a rebuild leaves this pointing at the previous generation's path.
            #
            # Only write into a real checkout: on a machine without one this would
            # create the tree from nothing.
            if [ -d "$MMS_HOME" ]; then
              cat > "$MMS_HOME/.bazelrc.local" <<EOF
        build --extra_execution_platforms=//toolchains/nodejs:linux_amd64
        build --host_platform=//toolchains/nodejs:linux_amd64
        build --shell_executable=${bazelShellWrapper}
        # Repository rules run with a stripped PATH. Pass it through so that tools
        # like uname (needed by aspect_rules_js platform detection) work.
        common --repo_env=PATH
        EOF
            fi

            # Only exec zsh when entering the shell interactively, not via direnv
            if [ -z "$DIRENV_IN_ENVRC" ]; then
              zsh
            fi
      '';
    };
}
