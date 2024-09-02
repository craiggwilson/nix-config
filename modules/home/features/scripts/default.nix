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
  cfg = config.hdwlinux.features.scripts;
in
{
  options.hdwlinux.features.scripts = with types; {
    enable = mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages =
      lib.optionals
        (
          config.hdwlinux.features.bash.enable
          && config.hdwlinux.features.fzf.enable
          && config.hdwlinux.features.ripgrep.enable
        )
        [
          (pkgs.writeShellScriptBin "ff" ''
            result=`rg --ignore-case --color=always --line-number --no-heading "$@" |
              fzf --ansi \
                --color 'hl:-1:underline,hl+:-1:underline:reverse' \
                --delimiter ':' \
                --preview "bat --color=always {1} --theme='Solarized (light)' --highlight-line {2}" \
                --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'`
            file="''${result%%:*}"
            linenumber=`echo "''${result}" | cut -d: -f2`
            if [ ! -z "''${file}" ]; then
              $EDITOR +"''${linenumber}" "$file"
            fi
          '')
        ]
      ++ lib.optionals (config.hdwlinux.features.desktop.hyprland.swaylock.enable) [
        (pkgs.writeShellScriptBin "lockscreen" ''
          1password --lock
          swaylock -f
        '')
      ];
  };
}
