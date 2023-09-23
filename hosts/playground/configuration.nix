{ config, pkgs, lib, ... }: {

  imports = [
    ../../hardware/qemu-guest-intel.nix

    ../../nixos/audio.nix
    ../../nixos/gnome-x.nix
    ../../nixos/networking.nix
    ../../nixos/printing.nix

    ../../nixos/1password.nix
    ../../nixos/openssh.nix
  ];

  system.stateVersion = "23.05";
  nixpkgs.config.allowUnfree = true;

  # Boot
  boot.loader.grub = {
    enable = true;
    devices = ["/dev/vda"];
  };

  # Timezone
  time.timeZone = "America/Chicago";

  # Networking
  networking.hostName = "playground";

  # Users
  users.users.craig = {
    isNormalUser = true;
    description = "Craig Wilson";
    extraGroups = [ "networkmanager" "wheel" "onepassword-cli" ];

    openssh.authorizedKeys.keyFiles = [
      ../../users/craig/programs/ssh/config/id_rsa.pub
    ];
  };
}
