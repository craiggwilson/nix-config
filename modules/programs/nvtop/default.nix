{
  config.substrate.modules.programs.nvtop = {
    tags = [ "capability:graphics:nvidia" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.nvtopPackages.full ];
    };
  };
}
