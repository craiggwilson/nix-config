{
  pkgs ? import <nixpkgs> { },
  lib,
}:
let
  javapkg = pkgs.temurin-bin-17;
in
(pkgs.buildFHSEnv {
  name = "observability";
  targetPkgs = pkgs: [
    # Bazel
    pkgs.bazelisk
    pkgs.gcc
    pkgs.glibc
    pkgs.libz
    pkgs.pkg-config
    pkgs.stable.bazel-buildtools

    # Java
    javapkg
    pkgs.google-java-format

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
    pkgs.openssh
    pkgs.yq
    pkgs.zip

    (pkgs.writeShellScriptBin "bazel" ''
      bazelisk $@
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
    export GOPRIVATE="github.com/10gen"
    export JAVA_HOME="${javapkg.home}";

    mkdir -p $TMPDIR
  '';
}).env
