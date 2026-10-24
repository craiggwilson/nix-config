{
  config.substrate.modules.programs.jq = {
    tags = [ "profile:programming" ];

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.jq ];
    };
  };
}
