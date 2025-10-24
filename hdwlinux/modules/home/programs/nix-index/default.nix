{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.nix-index;
in
{
  options.hdwlinux.programs.nix-index = {
    enable = lib.hdwlinux.mkEnableOption "nix-index" true;
  };

  config = lib.mkIf cfg.enable {
    programs.nix-index = {
      enable = true;
      enableBashIntegration = config.hdwlinux.programs.bash.enable;
      enableFishIntegration = false;
      enableZshIntegration = config.hdwlinux.programs.zsh.enable;
    };

    home.packages = [
      (pkgs.writeShellApplication {
        name = "nix-index-update";
        runtimeInputs = [ pkgs.wget ];
        text = ''
          filename="index-$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr "[:upper:]" "[:lower:]")"
          mkdir -p ~/.cache/nix-index && cd ~/.cache/nix-index
          wget -q -N "https://github.com/nix-community/nix-index-database/releases/latest/download/$filename"
          ln -f "$filename" files
        '';
      })
    ];
  };
}
