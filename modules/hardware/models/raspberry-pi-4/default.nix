{ inputs, ... }:
{
  config.substrate.modules.hardware.models.raspberry-pi-4 = {
    tags = [ "hardware:raspberry-pi-4" ];

    nixos = {
      imports = [ inputs.nixos-hardware.nixosModules.raspberry-pi-4 ];

      boot.loader.generic-extlinux-compatible.enable = true;
    };
  };
}
