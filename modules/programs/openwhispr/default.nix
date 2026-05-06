{
  config.substrate.modules.programs.openwhispr = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.openwhispr ];
      };
  };
}
