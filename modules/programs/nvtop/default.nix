{
  config.substrate.modules.programs.nvtop = {
    provides = [ "hardware:graphics:nvidia" ];
    tags = [ "graphics:nvidia" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.nvtopPackages.full ];
    };
  };
}
