{ inputs, ... }:
let
  hostname = "unsouled";
  diskoConfig = import ./_disko.nix;
  flakePath = "/home/craig/Projects/github.com/craiggwilson/nix-config/hdwlinux";
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
    nixos =
      { pkgs, ... }:
      {
        imports = [
          inputs.disko.nixosModules.disko
          diskoConfig
        ];

        boot = {
          kernelPackages = pkgs.linuxPackages_6_12;
          loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
          };
        };

        hdwlinux.flake = flakePath;

        system.stateVersion = "23.05";
      };

    homeManager = {
      hdwlinux.flake = flakePath;
    };
  };
}
