{
  config.substrate.modules.programs.jq = {
    provides = [ "programs:jq" "programming" ];
    tags = [ "programming" ];

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.jq ];
    };
  };
}
