{
  config.substrate.modules.programs.lsd = {
    provides = [ "programs:lsd" "programming" ];
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
