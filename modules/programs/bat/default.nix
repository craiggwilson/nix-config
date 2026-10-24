{
  config.substrate.modules.programs.bat = {
    tags = [ "profile:programming" ];

    homeManager = {
      programs.bat = {
        enable = true;
        config = {
          theme = "base16";
        };
      };
    };
  };
}
