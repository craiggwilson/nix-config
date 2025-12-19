{
  config.substrate.modules.programs.mergiraf = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.mergiraf ];

        programs.git.settings.merge = {
          conflictStyle = "zdiff3";
          mergiraf = {
            name = "mergiraf";
            driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P";
          };
        };
      };
  };
}

