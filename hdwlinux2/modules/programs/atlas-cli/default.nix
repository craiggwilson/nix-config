{
  config.substrate.modules.programs.atlas-cli = {
    tags = [ "programming" "users:craig:work" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.atlas-cli ];
      };
  };
}

