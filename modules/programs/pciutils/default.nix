{
  config.substrate.modules.programs.pciutils = {
    tags = [ "core:tools:system" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.pciutils ];
    };
  };
}
