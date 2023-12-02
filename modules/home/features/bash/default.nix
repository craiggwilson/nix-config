{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.bash;
in
{
  options.hdwlinux.features.bash = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
  };

  config.programs.bash = mkIf cfg.enable {
      enable = true;
      initExtra = ''
        source ~/.profile
      '';
      enableVteIntegration = true;
      historyControl = [
          "ignoredups"
          "ignorespace"
      ];
      historyIgnore = [
          "cd"
          "exit"
          "ls"
      ];
  };
}
