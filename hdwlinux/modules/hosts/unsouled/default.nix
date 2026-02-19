{ inputs, ... }:
let
  hostname = "unsouled";
  diskoConfig = import ./_disko.nix;
in
{
  substrate.hosts.${hostname} = {
    system = "x86_64-linux";
    users = [ "craig@work" ];
    tags = [
      "host:${hostname}"
    ];
  };

  substrate.modules.hosts.${hostname} = {
    tags = [ "host:${hostname}" ];
    generic = {
      hdwlinux.flake = "/home/craig/Projects/hdwlinux/nix-config/hdwlinux";
    };
    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        diskoConfig
      ];

      system.stateVersion = "23.05";
    };
  };
}
