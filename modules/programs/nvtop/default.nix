{
  config.substrate.modules.programs.nvtop = {
    provides = [ "programs:nvtop" "hardware:graphics:nvidia" ];
    tags = [ "graphics:nvidia" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.nvtopPackages.full ];
    };
  };
}
