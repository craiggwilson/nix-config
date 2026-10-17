{
  config.substrate.modules.programs.calibre = {
    provides = [
      "programs:calibre"
      "gui"
    ];
    requires = [ "profiles:personal" ];
    homeManager = {
      programs.calibre = {
        enable = true;
      };
    };
  };
}
