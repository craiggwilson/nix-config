{ inputs, ... }:
let
  hostname = "blackflame";
  diskoConfig = import ./_disko.nix;
in
{
  substrate.hosts.${hostname} = {
    system = "x86_64-linux";
    users = [ "craig@personal" ];
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
