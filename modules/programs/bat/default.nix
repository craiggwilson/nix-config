{
  config.substrate.modules.programs.bat = {
    provides = [
      "programs:bat"
      "programming"
    ];
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
