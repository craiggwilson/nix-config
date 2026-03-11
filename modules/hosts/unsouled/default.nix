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
    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        diskoConfig
      ];

      hdwlinux.theme.system = "catppuccin";
      system.stateVersion = "23.05";
    };
  };
}
