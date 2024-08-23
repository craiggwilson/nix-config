{
  lib,
  inputs,
  pkgs,
  stdenv,
  ...
}:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    # bazel
    (writeShellScriptBin "bazel" ''
      if [ -z "''${CONTAINER_ID}" ]; then
        exists=`distrobox list | rg mms-bazel`

        if [ -z "$exists" ]; then
          exec ${distrobox}/bin/distrobox-create -n mms-bazel -ap "awscli2 gcc-c++ libxcrypt-compat"
        fi

        exec ${distrobox}/bin/distrobox-enter -n mms-bazel -- /usr/bin/bazel "$@"
      else
        exec /usr/bin/bazel "$@"
      fi
    '')
    bazel-gazelle
    bazel-buildtools

    # go
    go_1_22

    #java
    temurin-bin-17

    # task runner
    just

    # node
    nodejs_18
    nodejs_18.pkgs.pnpm

    # python
    python3.pkgs.python
    python3.pkgs.venvShellHook

    # buf
    buf

    # from $MMS_HOME/scripts/onboarding/mms_onboarding/build_deps.py
    cairo
    giflib
    libjpeg
    libpng
    librsvg
    pango
    pkg-config

    # other
    openssl
    amazon-ecr-credential-helper
  ];

  venvDir = "./.venv";

  BAZEL_TELEMETRY = 0;
  GOPRIVATE = "github.com/10gen";
  JAVA_HOME = "${pkgs.temurin-bin-17.home}";
}
