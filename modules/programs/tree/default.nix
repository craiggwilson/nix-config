{
  config.substrate.modules.programs.tree = {
    tags = [ "core:tools:system" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.tree ];
    };
  };
}
