{ config, pkgs, lib, ...}: {

  # X Server
  services.xserver.enable = true;
  services.xserver.layout = "us";

  # Display Manager
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Networking
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    networkmanager-l2tp
  ];

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
    audio.enable = true;
    #jack.enable = false;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  security.rtkit.enable = true;

  # SSH
  services.openssh = {
    enable = true;
    # Require public key authentication
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };  

  # Programs
  programs.dconf.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "craig" ];
  };
}
