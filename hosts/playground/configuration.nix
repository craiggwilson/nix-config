# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

{
  imports = [
    ../../hardware/qemu-guest-intel.nix
  ];

  system.stateVersion = "23.05";

  networking.hostName = "playground";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";

  services = {
    openssh.enable = true;

    printing.enable = true;

    xserver = {
      enable = true;
      layout = "us";
      libinput.enable = true;

      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };
  }

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  users.users.craig = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  environment.systemPackages = with pkgs; [
    micro
    wget
  ];

  system.copySystemConfiguration = true;
}
