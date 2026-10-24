{
  config.substrate.modules.programs.lsd = {
    tags = [ "profile:programming" ];

    homeManager = {
      programs.lsd = {
        enable = true;
        settings = {
          icons.when = "auto";
        };
      };
    };
  };
}
