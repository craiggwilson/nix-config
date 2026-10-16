{
  config.substrate.modules.programs.jq = {
    provides = [ "programming" ];
    tags = [ "programming" ];

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.jq ];
    };
  };
}
