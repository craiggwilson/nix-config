{
  config.substrate.modules.programs.jq = {
    provides = [
      "programs:jq"
      "programming"
    ];
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.jq ];
    };
  };
}
