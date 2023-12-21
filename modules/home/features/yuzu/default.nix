{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.yuzu;
in
{
  options.hdwlinux.features.yuzu = with types; {
    enable = mkEnableOpt ["gaming" "gui"] config.hdwlinux.features.tags;
    backups = mkOption {
      description = "Backup options.";
      default = [];
      type = listOf(submodule {
        options = {
          game = mkOption { type = str; };
          remote = mkOption { type = path; };
        };
      });
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      yuzu-early-access
    ] ++ lib.optionals ((builtins.length cfg.backups) > 0) [
      (pkgs.writeShellScriptBin "yuzu-backup" ''
        dt=$(date +'%Y%m%d-%H%M%S')
        ${concatStringsSep "\n" (map (b: "mkdir -p ${b.remote}/$dt; cp -rf ${config.home.homeDirectory}/.local/share/yuzu/nand/user/save/0000000000000000/**/${b.game}/. ${b.remote}/$dt") cfg.backups)}
      '')
    ];

    home.shellAliases = {
      yuzu = "env -u WAYLAND_DISPLAY yuzu";
    };

    # /home/craig/.local/share/yuzu/nand/user/save/0000000000000000/B1652EE64C1FFF16A1D9F5E6D3E5CD7C/010015100B514000/
    # /home/craig/OneDrive/Games/Super Mario Wonder/
  };
}
