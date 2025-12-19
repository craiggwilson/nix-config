{
  config.substrate.modules.programs.lsd = {
    tags = [ "programming" ];

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

