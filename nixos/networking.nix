{ config, pkgs, lib, ...}: {
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    networkmanager-l2tp
  ];
}
