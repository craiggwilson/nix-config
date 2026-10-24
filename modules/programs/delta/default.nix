{
  config.substrate.modules.programs.delta = {
    tags = [ "profile:programming" ];

    homeManager = {
      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          navigate = true;
          light = false;
          side-by-side = true;
          line-numbers = true;
        };
      };
    };
  };
}
