{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.direnv;
in
{
  options.hdwlinux.programs.direnv = {
    enable = lib.hdwlinux.mkEnableOption "direnv" true;
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
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
          # Notice that we add shell variables to the function trigger.
          echo "$name \$*" >> "$target"
          chmod +x "$target"
        fi
      }
    '';
  };
}
