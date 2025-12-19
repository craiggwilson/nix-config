{
  config.substrate.modules.programs.jq = {
    tags = [ "programming" ];

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.jq ];
    };
  };
}

