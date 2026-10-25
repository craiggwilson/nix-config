{ inputs, lib, ... }:
{
  config.substrate.modules.hardware.models.raspberry-pi-4 = {
    tags = [ "hardware:raspberry-pi-4" ];

    nixos = {
      imports = [ inputs.nixos-hardware.nixosModules.raspberry-pi-4 ];

      # core:base enables systemd-boot, which cannot boot a Raspberry Pi; the
      # Pi's generic-extlinux-compatible loader is what the pi-4 module expects.
      boot = {
        loader.systemd-boot.enable = lib.mkForce false;
        loader.generic-extlinux-compatible.enable = true;
      };
    };
  };
}
