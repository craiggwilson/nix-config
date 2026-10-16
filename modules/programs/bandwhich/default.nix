{
  config.substrate.modules.programs.bandwhich = {
    provides = [ "core:networking" ];
    nixos = {
      programs.bandwhich = {
        enable = true;
      };
    };
  };
}
