{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.bash;
in
{
  options.hdwlinux.features.bash = with types; {
    enable = mkBoolOpt false "Whether or not to enable bash.";
    initExtra = mkOpt lines "" (mdDoc "Options passed directly to home-manager's `programs.bash.initExtra`.");
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.bash = {
      enable = true;
      initExtra = mkAliasDefinitions options.hdwlinux.features.bash.initExtra;
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
  };
}
