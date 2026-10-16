{
  config.substrate.modules.programs.lsd = {
    provides = [ "programming" ];
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
