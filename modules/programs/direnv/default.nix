{
  config.substrate.modules.programs.direnv = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [
          pkgs.direnv
          pkgs.nix-direnv
        ];

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

        files.".config/direnv/direnvrc".text = ''
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

        # nix-direnv loads from direnv's config lib dir (HM called it
        # hm-nix-direnv.sh; name is free).
        files.".config/direnv/lib/nix-direnv.sh".source = "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";
      };
  };
}
