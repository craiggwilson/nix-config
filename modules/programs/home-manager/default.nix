{
  config.substrate.modules.programs.home-manager = {
    tags = [ "core:base" ];
    homeManager = {
      programs.home-manager.enable = true;
    };
  };
}
