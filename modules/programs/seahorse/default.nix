{
  config.substrate.modules.programs.seahorse = {
    tags = [ "desktop" ];
    nixos = {
      programs.seahorse = {
        enable = true;
      };
    };
  };
}
