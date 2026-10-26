{ inputs, ... }:
let
  hostname = "unsouled";
  diskoConfig = import ./_disko.nix;
in
{
  substrate.hosts.${hostname} = {
    system = "x86_64-linux";
    nixpkgsConfig.cudaSupport = true;
    users = [ "craig@work" ];
    tags = [
      "host:${hostname}"
      "capability:cuda"
      "capability:displaylink"
      "capability:firmware"
      "capability:performance"
      "capability:printing"
      "capability:scanning"
      "capability:virtualization:docker"
      "core:base"
      "core:ssh"
      "hardware:dell-xps-15-9520"
      "location:raeford"
      "role:video-production"
      "role:workstation"
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

        boot.kernelPackages = pkgs.linuxPackages_6_18;

        hdwlinux.theme.system = "catppuccin";
        system.stateVersion = "23.05";
      };
  };
}
