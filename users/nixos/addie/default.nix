{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  username = "addie";
in
{
  nix.settings = {
    trusted-users = [ username ];
    allowed-users = [ username ];
  };

  users.users.${username} = {
    isNormalUser = true;

    name = username;
    home = "/home/${username}";
    group = "users";
    initialPassword = "password";

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKhxudRxx4UTvUK5xMAgG/uTuHfWTq9FuxO/Ffbc9iVoVWgNXiajv7F61xDld3XOqr925edPXPJuMrj0k5LXjIBRrFbCxY9+OL945WLU2fRNmoKYyBhHHv0+ArLApSC/ksvxBELzBc+S3voRflJ2mOe08OJX4IWqZ5714NXRpbWTEaTinw3zrNV+1V+Tolp7LZA6sjuMelWm25fNmJZnmkK5+b/0LMGdL21WrkuTFG2NopvdydjCjm/tV2+z10mmyIrcvFdD6C3n8ufRv1wpqhldOyA0OzyRmfEnyYsRyXrv2hlwq89DC4JBsIIwdxpl/DzDOTIxXs2acId+C/jhaI5O39O+eNLn1kosPnD2CWOfH0U8Wm7AcY1yEngZTjCBNtCGMEs+i7X3WTomubVL/4eo3cRYXFVR0+RQNBfEzoFT+PfD03Fc6PhR/2u9Q4CZx6Zqirgr3zlW5oJpvdB8iRiARckZ+95imeS0+kzPlQwO7TFYi/7wQGpDzdCp9zYYCFZ4enVg4RwyDflw0Pi8O8/GE/+AWAXFfofhxb85RS2b0ZKiAHGvgHGnZkNIsMtr/gNP2ukWlbK/ltvDUXtdR8oXTj02oxaVwohnmv7JWECMUIQ5nvxlvY8xMRojp2AySaHLw8bG/11vbRoackHyRfmkVK3ouZ8X+Q+TXJNivmGw== addiemwilson@outlook.com"
    ];

    extraGroups =
      [ "wheel" ]
      ++ (lib.optionals config.hdwlinux.programs._1password-cli.enable [ "onepassword-cli" ])
      ++ (lib.optionals config.hdwlinux.programs._1password-gui.enable [ "onepassword" ])
      ++ (lib.optionals config.hdwlinux.services.audio.enable [ "audio" ])
      ++ (lib.optionals config.hdwlinux.services.printing.enable [ "lp" ])
      ++ (lib.optionals config.hdwlinux.features.virtualization.docker.enable [ "docker" ])
      ++ (lib.optionals config.hdwlinux.features.networking.enable [ "networkmanager" ])
      ++ (lib.optionals config.hdwlinux.features.scanning.enable [ "scanner" ]);
  };

  programs._1password-gui.polkitPolicyOwners =
    lib.mkIf config.hdwlinux.programs._1password-gui.enable
      [ username ];
}
