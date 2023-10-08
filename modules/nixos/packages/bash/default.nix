{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.bash;
in
{
  options.hdwlinux.packages.bash = with types; {
    enable = mkBoolOpt false "Whether or not to enable bash.";
    initExtra = mkOpt lines "" (mdDoc "Options passed directly to home-manager's `programs.bash.initExtra`.");
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.bash = {
      enable = true;
      initExtra = mkAliasDefinitions options.hdwlinux.packages.bash.initExtra;
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
