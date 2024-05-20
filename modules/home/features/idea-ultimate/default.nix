{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.idea-community;
in
{
  options.hdwlinux.features.idea-community = with types; {
    enable = mkEnableOpt [
      "gui"
      "programming"
    ]
      config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    jetbrains.idea-ultimate
    (pkgs.writeShellScriptBin "idea" ''
      nohup ${jetbrains.idea-ultimate}/bin/idea-ultimate "$@" </dev/null >/dev/null 2>&1 &
      disown
    '')
  ];
}
