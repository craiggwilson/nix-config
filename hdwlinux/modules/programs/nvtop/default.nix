{
  config.substrate.modules.programs.nvtop = {
    tags = [ "graphics:nvidia" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.nvtopPackages.full ];
    };
  };
}

