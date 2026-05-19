{
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
in
pkgs.mkShell {
  buildInputs = [
    # Bazel
    pkgs.bazelisk
    pkgs.gcc
    pkgs.glibc
    pkgs.hdwlinux.engflow_auth
    pkgs.libz
    pkgs.pkg-config
    pkgs.bazel-buildtools

    # Java
    javapkg
    pkgs.google-java-format

    # Go
    pkgs.go_1_25

    # node
    pkgs.nodejs_22
    pkgs.pnpm

    # python
    pkgs.openblas
    pkgs.python3.pkgs.python

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
    (pkgs.openssh.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./openssh.patch ];
      doCheck = false;
    }))
    pkgs.yq
    pkgs.zip

    pkgs.cairo
    pkgs.giflib
    pkgs.libjpeg
    pkgs.libpng
    pkgs.librsvg
    pkgs.pango

    (pkgs.writeShellScriptBin "bazel" ''
      bazelisk "$@"
    '')

    (pkgs.writeShellScriptBin "start-mongod" ''
      $MMS_HOME/scripts/mongodb-start-standalone.bash
    '')

    (pkgs.writeShellScriptBin "start-mongod-for-test" ''
      $MMS_HOME/scripts/mongodb-start-standalone.bash -p 26000
    '')
  ];

  nativeBuildInputs = [
    pkgs.python3.pkgs.venvShellHook
  ];

  LD_LIBRARY_PATH = lib.makeLibraryPath [
    pkgs.glibc
    pkgs.libz
    pkgs.openssl
  ];

  venvDir = "./.venv";

  AWS_PROFILE = "mms-scratch";
  BAZEL_SKIP_ENGFLOW_CERT_CHECK = 1;
  BAZEL_TELEMETRY = 0;
  FERN_BASE_DIRECTORY = "$XDG_DATA_HOME/fern";
  GOPRIVATE = "github.com/10gen";
  JAVA_HOME = javapkg.home;

  shellHook = ''
    export MMS_HOME="$PWD"
    mkdir -p "$TMPDIR"

    # Bazel's built-in CopyFile action runs `exec env -` stripping all env vars;
    # --action_env and BASH_ENV are both ignored by it. We fix this by pointing
    # --shell_executable at a wrapper that unconditionally sets coreutils on PATH.
    # Rewrite .bazelrc.local with the current nix store path (changes on rebuild).
    cat > "$MMS_HOME/.bazelrc.local" <<EOF
build --extra_execution_platforms=//toolchains/nodejs:linux_amd64
build --host_platform=//toolchains/nodejs:linux_amd64
build --shell_executable=${bazelShellWrapper}
# Repository rules run with a stripped PATH. Pass it through so that tools
# like uname (needed by aspect_rules_js platform detection) work.
common --repo_env=PATH
EOF

    # Only exec zsh when entering the shell interactively, not via direnv
    if [ -z "$DIRENV_IN_ENVRC" ]; then
      exec zsh
    fi
  '';
}
