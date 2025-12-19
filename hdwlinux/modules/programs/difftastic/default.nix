{
  config.substrate.modules.programs.difftastic = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.difftastic ];

        programs.git.settings = {
          diff.tool = "difft";
          difftool = {
            prompt = false;
            difft.cmd = ''difft "$LOCAL" "$REMOTE"'';
          };
        };
      };
  };
}

