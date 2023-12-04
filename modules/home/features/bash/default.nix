{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.bash;
in
{
  options.hdwlinux.features.bash = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    programs.bash = {
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

    home.packages = mkIf (config.hdwlinux.features.fzf.enable && config.hdwlinux.features.ripgrep.enable) [
      (pkgs.writeShellScriptBin "frg" ''
        result = `rg --ignore-case --color=always --line-number --no-heading "$@" |
          fzf --ansi \
            --color 'hl:-1:underline,hl+:-1:underline:reverse' \
            --delimiter ':' \
            --preview "bat --color=always {1} --theme='Solarized (light)' --highlight-line {2}" \
            --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'`
        file = "''${result%%:*}"
        linenumber = `echo "''${result}" | cut -d: -f2`
        if [ ! -z "''${file}" ]; then
          $EDITOR +"''${linenumber}" "$file"
        fi
      '')
    ];
  };
}
