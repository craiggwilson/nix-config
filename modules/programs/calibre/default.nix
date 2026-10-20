{
  config.substrate.modules.programs.calibre = {
    tags = [
      "desktop"
      "users:craig:personal"
    ];

    homeManager = {
      programs.calibre = {
        enable = true;
      };
    };
  };
}
