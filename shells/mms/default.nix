{
  pkgs ? import <nixpkgs> { },
  lib,
}:
let
  javapkg = pkgs.temurin-bin-17;
in
(pkgs.buildFHSEnv {
  name = "mms";
  targetPkgs = pkgs: [
    # Bazel
    pkgs.bazelisk
    pkgs.gcc
    pkgs.glibc
    pkgs.hdwlinux.engflow_auth
    pkgs.libz
    pkgs.pkg-config
    pkgs.stable.bazel-buildtools

    # Java
    javapkg
    pkgs.google-java-format

    # Go
    pkgs.go_1_24

    # node
    pkgs.nodejs_22
    pkgs.nodejs_22.pkgs.pnpm

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
      bazelisk $@
    '')

    (pkgs.writeShellScriptBin "start-mongod" ''
      $MMS_HOME/scripts/mongodb-start-standalone.bash
    '')

    (pkgs.writeShellScriptBin "start-mongod-for-test" ''
      $MMS_HOME/scripts/mongodb-start-standalone.bash -p 26000
    '')
  ];

  includeClosures = true;
  runScript = "zsh";
  profile = ''
    export LD_LIBRARY_PATH=${
      lib.makeLibraryPath [
        pkgs.glibc
        "/usr/lib"
        "$LD_LIBRARY_PATH"
      ]
    } 
    export venvDir="./.venv"

    export AWS_PROFILE="mms-scratch"
    export BAZEL_SKIP_ENGFLOW_CERT_CHECK=1
    export BAZEL_TELEMETRY=0
    export FERN_BASE_DIRECTORY="$XDG_DATA_HOME/fern"
    export GOPRIVATE="github.com/10gen"
    export JAVA_HOME="${javapkg.home}";
    export MMS_HOME="$PWD";

    mkdir -p $TMPDIR
  '';
}).env
