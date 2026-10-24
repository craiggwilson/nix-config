{
  config.substrate.modules.programs.coreutils = {
    tags = [ "core:base" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.coreutils ];
    };
  };
}
