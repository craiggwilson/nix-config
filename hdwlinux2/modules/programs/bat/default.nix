{
  config.substrate.modules.programs.bat = {
    tags = [ "programming" ];

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
