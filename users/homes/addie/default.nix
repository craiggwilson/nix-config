{ lib, pkgs, inputs, config, flake, ... }:
{
  hdwlinux = {
    user = {
      fullName = "Addie Wilson";
      email = "addiemwilson@outlook.com";
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKhxudRxx4UTvUK5xMAgG/uTuHfWTq9FuxO/Ffbc9iVoVWgNXiajv7F61xDld3XOqr925edPXPJuMrj0k5LXjIBRrFbCxY9+OL945WLU2fRNmoKYyBhHHv0+ArLApSC/ksvxBELzBc+S3voRflJ2mOe08OJX4IWqZ5714NXRpbWTEaTinw3zrNV+1V+Tolp7LZA6sjuMelWm25fNmJZnmkK5+b/0LMGdL21WrkuTFG2NopvdydjCjm/tV2+z10mmyIrcvFdD6C3n8ufRv1wpqhldOyA0OzyRmfEnyYsRyXrv2hlwq89DC4JBsIIwdxpl/DzDOTIxXs2acId+C/jhaI5O39O+eNLn1kosPnD2CWOfH0U8Wm7AcY1yEngZTjCBNtCGMEs+i7X3WTomubVL/4eo3cRYXFVR0+RQNBfEzoFT+PfD03Fc6PhR/2u9Q4CZx6Zqirgr3zlW5oJpvdB8iRiARckZ+95imeS0+kzPlQwO7TFYi/7wQGpDzdCp9zYYCFZ4enVg4RwyDflw0Pi8O8/GE/+AWAXFfofhxb85RS2b0ZKiAHGvgHGnZkNIsMtr/gNP2ukWlbK/ltvDUXtdR8oXTj02oxaVwohnmv7JWECMUIQ5nvxlvY8xMRojp2AySaHLw8bG/11vbRoackHyRfmkVK3ouZ8X+Q+TXJNivmGw== addiemwilson@outlook.com";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  home.stateVersion = "23.05";
}
