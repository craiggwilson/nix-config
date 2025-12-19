{
  config.substrate.modules.programs.seahorse = {
    tags = [ "gui" ];
    nixos = {
      programs.seahorse = {
        enable = true;
      };
    };
  };
}

