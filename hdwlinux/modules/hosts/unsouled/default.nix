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
    nixpkgsConfig = {
      allowUnfree = true;
      cudaSupport = true;
    };
  };

  substrate.modules.hosts.${hostname} = {
    tags = [ "host:${hostname}" ];
    generic = {
      hdwlinux.flake = "/home/craig/Projects/github.com/craiggwilson/nix-config/hdwlinux";
    };
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

        system.stateVersion = "23.05";
      };
  };
}
