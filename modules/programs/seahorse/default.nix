{
  config.substrate.modules.programs.seahorse = {
    provides = [ "gui" ];
    tags = [ "gui" ];
    nixos = {
      programs.seahorse = {
        enable = true;
      };
    };
  };
}
