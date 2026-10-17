{
  config.substrate.modules.programs.calibre = {
    provides = [
      "programs:calibre"
      "gui"
    ];
    requires = [
      "gui"
      "profiles:personal"
    ];
    homeManager = {
      programs.calibre = {
        enable = true;
      };
    };
  };
}
