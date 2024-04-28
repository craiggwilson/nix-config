{ lib, inputs, pkgs, stdenv,...}:

(pkgs.buildFHSEnv  {
  name = "bazel";
  targetPkgs = pkgs: [
    pkgs.bazel
    pkgs.cacert
    pkgs.gcc
    pkgs.glibc
    pkgs.git
    pkgs.libxcrypt
    pkgs.libxcrypt-legacy
    pkgs.openssh
    pkgs.openssl
  ];
}).env
