{
  config.substrate.modules.programs.dconf = {
    provides = [ "core:utils" ];
    nixos = {
      programs.dconf.enable = true;
    };
  };
}
