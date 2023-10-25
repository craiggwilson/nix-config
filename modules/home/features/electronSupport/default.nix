{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.electronSupport;
in
{
  options.hdwlinux.features.electronSupport = with types; {
    enable = mkBoolOpt false "Whether or not to enable electron support.";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    xdg.configFile."electron-flags.conf".text = ''
      --enable-features=UseOzonePlatform
      --ozone-platform=wayland
    '';
  };
}
