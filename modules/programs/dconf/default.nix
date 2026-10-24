{
  config.substrate.modules.programs.dconf = {
    tags = [ "desktop" ];
    nixos = {
      programs.dconf.enable = true;
    };
  };
}
