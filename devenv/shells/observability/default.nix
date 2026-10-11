{
  substrate.devenv.shells.observability =
    {
      lib,
      pkgs,
      ...
    }:
    let
      javapkg = pkgs.temurin-bin-17;

      packages = with pkgs; [
        # Bazel
        bazelisk
        gcc
        glibc
        libz
        stable.bazel-buildtools

        # Java
        temurin-bin-17
        google-java-format

        # other
        amazon-ecr-credential-helper
        buf
        dyff
        graphviz
        just
        kubernetes-helm
        libxml2
        pre-commit
        openssl
        openssh
        yq
        zip
      ];
    in
    {
      # See the note in shells/go: PWD when the evaluation can see it, the literal
      # when it cannot.
      devenv.root =
        let
          pwd = builtins.getEnv "PWD";
        in
        if pwd != "" then pwd else "/home/craig";
      inherit packages;
      scripts.bazel.exec = ''bazelisk "$@"'';
      env = {
        # No glibc here. Putting one in LD_LIBRARY_PATH overrides the libc that
        # devenv's own tooling (devenv-tasks) was built against, and a mismatched
        # libc fails at load with "__pointer_chk_guard, version GLIBC_PRIVATE".
        # The shell already runs on the system libc, so there is nothing to add.
        LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.openssl ];
        GOPRIVATE = "github.com/10gen";
        JAVA_HOME = javapkg.home;
      };
      # Not `exec`: replacing this shell makes `nix develop .#observability --command
      # ...` print nothing, because zsh takes over before the command runs.
      enterShell = ''
        mkdir -p "$TMPDIR"
        zsh
      '';
    };
}
