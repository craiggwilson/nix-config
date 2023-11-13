{ pkgs, ... }:
(pkgs.buildFHSUserEnv {
  name = "mms";
  targetPkgs = pkgs: (with pkgs; [
    bazel
    binutils
    gcc
    git
    glibc
    openssh
  ]);
}).env
