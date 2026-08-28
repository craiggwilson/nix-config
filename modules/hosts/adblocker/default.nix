{ inputs, lib, ... }:
let
  hostname = "adblocker";
in
{
  substrate.hosts.${hostname} = {
    system = "aarch64-linux";
    tags = [ "host:${hostname}" ];
  };

  substrate.modules.hosts.${hostname} = {
    tags = [ "host:${hostname}" ];

    nixos = {
      imports = [
        inputs.nixos-hardware.nixosModules.raspberry-pi-3
      ];

      boot = {
        loader = {
          grub.enable = false;
          generic-extlinux-compatible.enable = true;
        };

        kernelPackages = inputs.nixpkgs.legacyPackages.aarch64-linux.linuxPackages;
        kernelParams = [ "console=ttyS1,115200n8" ];
      };

      hardware.enableRedistributableFirmware = true;
      hardware.raspberry-pi.firmware = {
        enable = true;
        path = "/boot/firmware";
        uboot.enable = true;
      };

      networking = {
        hostName = hostname;
        nameservers = [ "127.0.0.1" ];
        useDHCP = lib.mkDefault true;
        wireless.enable = false;
      };

      fileSystems."/boot/firmware" = {
        device = "/dev/disk/by-label/FIRMWARE";
        fsType = "vfat";
        options = [ "nofail" "noauto" ];
      };

      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };

      hdwlinux.flake = "/home/craig/Projects/hdwlinux/nix-config";

      services.openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          KbdInteractiveAuthentication = false;
          PasswordAuthentication = false;
          X11Forwarding = false;
        };
      };

      system.stateVersion = "23.05";

      users.extraUsers.root.openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL5nMCsw3AQ1HaLzvLGW51yjlKGXGR0ECeEb/WAuIGBdKs+nKo7W40d9cXN/XYH6YWZXhg/mw6RFOP5K7CB1FlVozVOqSvso2GcCUCBacjCXWrnubRUsJ5mHDdsmm3jwYGzaSNjgutVpwtj0+ijwACS5C7/m2QpatSdYFOuQhNk1KhaatoKhwWuOeh5kbpWCwUZTtTwrzphegIFDWgfErWwa0O2LKI1cVsFZkT/SgKkjILDfNJ1sYL98tKPouNrMMZj+5/tV1vxIY3UFsbAY78lZUY1yeHmTdJBjwxtG9P7+Dw4CJf9RjS35eCUA84hw95GRVfGAMj/8VasTnHsstvuNiG58lp8ufbfC8T/wGPNH7LwPmqV0TdD26s2nTikvC0qiy/QU58IeXXahI2/dmaWK+qfCayw3sL2DS/5A+HLl09lpVLLNhChnN//0mvUy0to0rCbFwqFXwmIHlveGlYdkEoRiYD4jnu/aTLfnW6YC3Ew1wVyJRH3QHXIIbWafs7R6owHWhcWEe6/CYEDAq1RTy4dknXR7DTbqhKgPX+1FnG9l9GilAwRlsb1qThHikpj2LcRvj0t0tKNO92guUAFqPyByrN9CGDimefiRqZHXkwPTl0Cr4sq3xfuW9J3wgA0u0yieLQO6EKE8adLzOfrzHEathtg+anUPYg84n2Dw== craiggwilson@gmail.com"
      ];
    };
  };
}
