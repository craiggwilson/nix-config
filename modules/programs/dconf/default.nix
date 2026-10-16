{
  config.substrate.modules.programs.dconf = {
    provides = [ "programs:dconf" "core:utils" ];
    nixos = {
      programs.dconf.enable = true;
    };
  };
}
