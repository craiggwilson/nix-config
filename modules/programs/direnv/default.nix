{
  config.substrate.modules.programs.direnv = {
    tags = [ "programming" ];

    # direnvrc + nix-direnv install stay home-manager-side until the direnv
    # config wave; only the hook lines move here.
    perUser =
      { pkgs, ... }:
      {
        hdwlinux.shell.zsh.initLines = [
          {
            prio = 450;
            text = "eval \"$(${pkgs.direnv}/bin/direnv hook zsh)\"";
          }
        ];
        hdwlinux.shell.bash.initLines = [
          {
            prio = 540;
            text = "eval \"$(${pkgs.direnv}/bin/direnv hook bash)\"";
          }
        ];
      };

    homeManager =
      { config, ... }:
      {
        programs.direnv = {
          enable = true;
          enableBashIntegration = config.programs.bash.enable;
          enableZshIntegration = config.programs.zsh.enable;
          nix-direnv.enable = true;
        };

        xdg.configFile."direnv/direnvrc".text = ''
          export_alias() {
            local name=$1
            shift
            local alias_dir=$PWD/.direnv/aliases
            local target="$alias_dir/$name"
            local oldpath="$PATH"
            mkdir -p "$alias_dir"
            if ! [[ ":$PATH:" == *":$alias_dir:"* ]]; then
              PATH_add "$alias_dir"
            fi

            echo "#!/usr/bin/env bash" > "$target"
            echo "PATH=$oldpath" >> "$target"
            echo "$@" >> "$target"
            chmod +x "$target"
          }

          export_function() {
            local name=$1
            local alias_dir=$PWD/.direnv/aliases
            mkdir -p "$alias_dir"
            PATH_add "$alias_dir"
            local target="$alias_dir/$name"
            if declare -f "$name" >/dev/null; then
              echo "#!$SHELL" > "$target"
              declare -f "$name" >> "$target" 2>/dev/null
              echo "$name \$*" >> "$target"
              chmod +x "$target"
            fi
          }
        '';
      };
  };
}

