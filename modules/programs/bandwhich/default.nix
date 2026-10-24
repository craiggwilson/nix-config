{
  config.substrate.modules.programs.bandwhich = {
    tags = [ "core:tools:system" ];
    nixos = {
      programs.bandwhich = {
        enable = true;
      };
    };
  };
}
