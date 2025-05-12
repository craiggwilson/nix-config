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
    #pkgs.bazel_7
    pkgs.bazelisk
    pkgs.bazel-gazelle
    pkgs.gcc
    pkgs.glibc
    pkgs.libz
    pkgs.pkg-config
    pkgs.stable.bazel-buildtools
    pkgs.unzip

    # Java
    javapkg
    pkgs.google-java-format

    # Go
    pkgs.go_1_23

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
    pkgs.yq

    pkgs.cairo
    pkgs.giflib
    pkgs.libjpeg
    pkgs.libpng
    pkgs.librsvg
    pkgs.pango

    (pkgs.writeShellScriptBin "render-helm" ''
      deploy="$1"
      name="$2"
      topo="''${3-:'aws.dev'}"

      filter="{chart: (\"xgen/\" + .deployments.\"''${name}\".chart_name), values: (.deployments.\"''${name}\".chart_values + .deployments.\"''${name}\".topology.\"*.''${topo}\".chart_values | \"--values \" + join(\" --values \"))} | \"helm template ''${name} \(.chart) \(.values)\""

      CMD=$(cat "$deploy" | yq "$filter" | tr -d '"')

      #echo $CMD
      eval "$CMD"
    '')

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
