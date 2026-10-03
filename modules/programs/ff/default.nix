{
  config.substrate.modules.programs.ff = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, wrap, ... }:
      {
        home.packages = [
          (wrap.package {
            package = pkgs.writeShellApplication {
              name = "ff";
              runtimeInputs = [
                pkgs.ripgrep
                pkgs.fzf
                pkgs.bat
                pkgs.coreutils
              ];
              text = ''
                result=$(rg --ignore-case --color=always --line-number --no-heading "$@" |
                  fzf --ansi \
                    --color 'hl:-1:underline,hl+:-1:underline:reverse' \
                    --delimiter ':' \
                    --preview "bat --color=always {1} --theme='Solarized (light)' --highlight-line {2}" \
                    --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')
                file="''${result%%:*}"
                linenumber=$(echo "''${result}" | cut -d: -f2)
                if [ ! -z "''${file}" ]; then
                  $EDITOR +"''${linenumber}" "$file"
                fi
              '';
            };
          })
        ];
      };
  };
}

