# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, lib, ... }:

{
  imports = [
    ../../hardware/qemu-guest-intel.nix
  ];

  boot.loader.grub = {
    enable = true;
    devices = ["/dev/vda"];
  };

  system.stateVersion = "23.05";
  nixpkgs.config.allowUnfree = true;

    # Timezone
  time.timeZone = "America/Chicago";

  # Networking
  networking.hostName = "playground";
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  # X Server
  services.xserver.enable = true;

  # Display/Desktop
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Keymap
  services.xserver.layout = "us";
  
  # Touchpad
  services.xserver.libinput.enable = true;

  # Printing
  services.printing.enable = true;

  # Sound
  sound.enable = true;
  hardware.pulseaudio.enable = false; # enable with pipewire
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  # Users
  users.users.craig = {
    isNormalUser = true;
    description = "Craig Wilson";
    extraGroups = [ "networkmanager" "wheel" "onepassword-cli" ];

    openssh.authorizedKeys.keyFiles = [
      ../../users/craig/features/ssh/config/id_rsa.pub
    ];
  };

  services.xserver.displayManager.autoLogin = { 
    enable = true;
    user = "craig";
  };

  systemd.services."getty@tty1".enable = false; # workaround for issues with gnome autologin.
  systemd.services."autovt@tty1".enable = false;

  # System
  environment.systemPackages = with pkgs; [
    wget
    xclip
  ];

  # SSH
  services.openssh = {
    enable = true;
    # Require public key authentication
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # 1password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "craig" ];
  };
}
