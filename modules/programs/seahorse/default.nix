{
  config.substrate.modules.programs.seahorse = {
    provides = [ "programs:seahorse" "gui" ];
    tags = [ "gui" ];
    nixos = {
      programs.seahorse = {
        enable = true;
      };
    };
  };
}
