{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.mongodb;
in
{
  options.hdwlinux.features.mongodb = with types; {
    enable = mkBoolOpt false "Whether or not to enable mongodb.";
  };

  config.environment.systemPackages =
    with pkgs;
    mkIf cfg.enable [
      (pkgs.writeShellScriptBin "mongod" ''
        if [ -z "''${CONTAINER_ID}" ]; then
          exists=`distrobox list | rg mongod`

          if [ -z "$exists" ]; then
            exec ${pkgs.distrobox}/bin/distrobox-create -n mongodb -ap ""
          fi

          exec ${pkgs.distrobox}/bin/distrobox-enter -n mongodb -- /usr/bin/mongod "$@"
        else
          exec /usr/bin/mongod "$@"
        fi
      '')
      #mongodb-5_0
    ];
}
