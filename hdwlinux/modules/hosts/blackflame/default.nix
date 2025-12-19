{ inputs, lib, ... }:
let
  hostname = "blackflame";
  diskoConfig = import ./_disko.nix;
  flakePath = "/home/craig/Projects/github.com/craiggwilson/nix-config/hdwlinux";
in
{
  substrate.hosts.${hostname} = {
    system = "x86_64-linux";
    users = [ "craig@personal" ];
    tags = [
      "host:${hostname}"
    ];
  };

  substrate.modules.hosts.${hostname} = {
    tags = [ "host:${hostname}" ];

    nixos =
      { pkgs, ... }:
      {
        imports = [
          inputs.disko.nixosModules.disko
          diskoConfig
        ];

        hdwlinux.flake = flakePath;

        system.stateVersion = "23.05";
      };

    homeManager = {
      hdwlinux.flake = flakePath;
    };
  };
}
