{
  config.substrate.modules.programs.libqalculate = {
    provides = [
      "programs:libqalculate"
      "gui"
    ];
    requires = [ "gui" ];
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.libqalculate ];
    };
  };
}
