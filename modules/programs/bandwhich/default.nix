{
  config.substrate.modules.programs.bandwhich = {
    provides = [
      "programs:bandwhich"
      "core:networking"
    ];
    nixos = {
      programs.bandwhich = {
        enable = true;
      };
    };
  };
}
