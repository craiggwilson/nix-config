{
  config.substrate.modules.programs.bat = {
    provides = [ "programming" ];
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
