{
  config.substrate.modules.programs.seahorse = {
    provides = [
      "programs:seahorse"
      "gui"
    ];
    requires = [ "gui" ];
    nixos = {
      programs.seahorse = {
        enable = true;
      };
    };
  };
}
