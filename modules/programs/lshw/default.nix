{
  config.substrate.modules.programs.lshw = {
    tags = [ "core:tools:system" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.lshw ];
    };
  };
}
