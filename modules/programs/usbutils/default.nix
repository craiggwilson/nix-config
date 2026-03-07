{
  config.substrate.modules.programs.usbutils = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.usbutils ];
    };
  };
}

