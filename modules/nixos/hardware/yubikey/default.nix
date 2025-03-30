{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.hardware.yubikey;
in
{
  options.hdwlinux.hardware.yubikey = {
    enable = config.lib.hdwlinux.mkEnableOption "yubikey" "yubikey";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [
        pkgs.yubikey-manager
      ]
      ++ lib.optionals (lib.hdwlinux.matchTag "gui" config.hdwlinux.tags) [
        pkgs.yubikey-manager-qt
      ];
  };
}
