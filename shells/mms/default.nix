{ lib
, inputs
, pkgs
, stdenv
, ...
}:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    # bazel
    (pkgs.writeShellScriptBin "bazel" ''
      if [ -z "''${CONTAINER_ID}" ]; then
        exists=`distrobox list | rg mms-bazel`

        if [ -z "$exists" ]; then
          exec ${pkgs.distrobox}/bin/distrobox-create -n mms-bazel -ap "awscli2 gcc-c++ libxcrypt-compat"
        fi

        exec ${pkgs.distrobox}/bin/distrobox-enter -n mms-bazel -- /usr/bin/bazel "$@"
      else
        exec /usr/bin/bazel "$@"
      fi
    '')

    # go
    go_1_21

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
  ];

  venvDir = "./.venv";

  BAZEL_TELEMETRY = 0;
  JAVA_HOME = "${pkgs.temurin-bin-17.home}";
}
