{
  config.substrate.modules.programs.difftastic = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.difftastic ];

        hdwlinux.programs.git.configFragments = [
          {
            diff.tool = "difft";
            difftool = {
              prompt = false;
              difft.cmd = ''difft "$LOCAL" "$REMOTE"'';
            };
          }
        ];
      };
  };
}
