{ lib, pkgs, inputs, config, ... }:
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.mms-bazel;
  name = "mms-bazel";
in
{
  options.hdwlinux.features.mms-bazel = with types; {
    enable = mkEnableOpt ["cli" "programming" "work"] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin name ''
        if [ -z "''${CONTAINER_ID}" ]; then
          exists=`distrobox list | rg ${name}`

          if [ -z "$exists" ]; then
            exec ${pkgs.distrobox}/bin/distrobox-create -n ${name} -ap "awscli2 gcc-c++ libxcrypt-compat"
          fi

          exec ${pkgs.distrobox}/bin/distrobox-enter -n ${name} -- /usr/bin/bazel "$@"
        else
          exec /usr/bin/bazel "$@"
        fi
      '')
    ];
  };
}
