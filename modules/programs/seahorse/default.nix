{
  config.substrate.modules.programs.seahorse = {
    provides = [
      "programs:seahorse"
      "gui"
    ];
    nixos = {
      programs.seahorse = {
        enable = true;
      };
    };
  };
}
