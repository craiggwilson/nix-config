{
  config.substrate.modules.programs.calibre = {
    tags = [
      "gui"
      "users:craig:personal"
    ];

    homeManager = {
      programs.calibre = {
        enable = true;
      };
    };
  };
}
