{
  config.substrate.modules.programs.bat = {
    provides = [ "programs:bat" "programming" ];
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
