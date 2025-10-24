{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

let
  cfg = config.hdwlinux.scripts;
in
{
  options.hdwlinux.scripts = {
    enable = lib.hdwlinux.mkEnableOption "scripts" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "ff" ''
        result=`${pkgs.ripgrep}/bin/rg --ignore-case --color=always --line-number --no-heading "$@" |
          ${pkgs.fzf}/bin/fzf --ansi \
            --color 'hl:-1:underline,hl+:-1:underline:reverse' \
            --delimiter ':' \
            --preview "${pkgs.bat}/bin/bat --color=always {1} --theme='Solarized (light)' --highlight-line {2}" \
            --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'`
        file="''${result%%:*}"
        linenumber=`echo "''${result}" | cut -d: -f2`
        if [ ! -z "''${file}" ]; then
          $EDITOR +"''${linenumber}" "$file"
        fi
      '')
    ];
  };
}
