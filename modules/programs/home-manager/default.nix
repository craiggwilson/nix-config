{
  config.substrate.modules.programs.home-manager = {
    provides = [ "core:home" ];
    homeManager = {
      programs.home-manager.enable = true;
    };
  };
}
