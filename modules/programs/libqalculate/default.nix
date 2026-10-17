{
  config.substrate.modules.programs.libqalculate = {
    provides = [
      "programs:libqalculate"
      "gui"
    ];
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.libqalculate ];
    };
  };
}
