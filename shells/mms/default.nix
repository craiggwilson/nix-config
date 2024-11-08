{
  pkgs,
  ...
}:

pkgs.mkShell {
  buildInputs = [
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
    pkgs.bazel-gazelle
    pkgs.bazel-buildtools

    # go
    pkgs.go_1_22

    #java
    pkgs.temurin-bin-17

    # task runner
    pkgs.just

    # node
    pkgs.nodejs_18
    pkgs.nodejs_18.pkgs.pnpm

    # python
    pkgs.python3.pkgs.python
    pkgs.python3.pkgs.venvShellHook
    pkgs.openblas

    # buf
    pkgs.buf

    pkgs.cairo
    pkgs.giflib
    pkgs.libjpeg
    pkgs.libpng
    pkgs.librsvg
    pkgs.pango
    pkgs.pkg-config

    # other
    pkgs.graphviz
    pkgs.openssl
    pkgs.amazon-ecr-credential-helper

    # fern
    pkgs.hdwlinux.fern
    pkgs.minikube
    pkgs.tilt
    (pkgs.writeShellScriptBin "fern-init" ''
      minikube start --driver=docker

      minikube addons enable metallb
      MINIKUBE_IP=$(minikube ip)
      cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: ConfigMap
      metadata:
        namespace: metallb-system
        name: config
      data:
        config: |
          address-pools:
          - name: default
            protocol: layer2
            addresses:
            - $MINIKUBE_IP/32
      EOF

      kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
    '')
  ];

  venvDir = "./.venv";

  BAZEL_TELEMETRY = 0;
  GOPRIVATE = "github.com/10gen";
  JAVA_HOME = "${pkgs.temurin-bin-17.home}";

  shellHook = ''
    kubectl config use-context minikube
  '';
}
