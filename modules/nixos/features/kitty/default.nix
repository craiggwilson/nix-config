{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.kitty;
in
{
  options.hdwlinux.features.kitty = with types; {
    enable = mkBoolOpt false "Whether or not to enable kitty.";
    extraConfig = mkStrOpt "" (mdDoc "Option passed to home-manager's `programs.kitty.extraConfig`.");
  };

  config.hdwlinux.home = mkIf cfg.enable {
    programs.kitty =  {
      enable = true;
      extraConfig = cfg.extraConfig + ''
        map ctrl+c copy_or_interrupt
        map ctrl+v paste_from_clipboard

        enable_audio_bell no
        tab_bar_style powerline
        tab_bar_edge = top
      '';
    };
  };
}
