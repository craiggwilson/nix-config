{
  config.substrate.modules.programs.usbutils = {
    tags = [ "core:tools:system" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.usbutils ];
    };
  };
}
