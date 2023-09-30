{ config, pkgs, lib, nixos-hardware, ... }: {

  imports = [
    ../../hardware/microsoft-surface-book-2.nix

    ../../nixos/audio.nix
    ../../nixos/gnome-x.nix
    ../../nixos/networking.nix
    ../../nixos/printing.nix

    ../../nixos/1password.nix
    ../../nixos/openssh.nix
  ];

  system.stateVersion = "23.05";
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = true;

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  # Timezone
  time.timeZone = "America/Chicago";

  # Networking
  networking.hostName = "ghostwater";

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
