{
  config.substrate.modules.programs.gh = {
    tags = [ "programming" ];

    homeManager = {
      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
          prompt = "enabled";
        };
      };

      programs.gh-dash = {
        enable = true;
      };
    };
  };
}

