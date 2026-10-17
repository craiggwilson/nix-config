{
  config.substrate.modules.programs.home-manager = {
    provides = [
      "programs:home-manager"
      "core:home"
    ];
    homeManager = {
      programs.home-manager.enable = true;
    };
  };
}
