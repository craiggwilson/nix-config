{
  config.substrate.modules.programs.usbutils = {
    provides = [ "programs:usbutils" "core:networking" ];
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.usbutils ];
    };
  };
}
