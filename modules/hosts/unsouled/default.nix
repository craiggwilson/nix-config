{ inputs, ... }:
let
  hostname = "unsouled";
  diskoConfig = import ./_disko.nix;
in
{
  substrate.hosts.${hostname} = {
    system = "x86_64-linux";
    nixpkgsConfig = {
      cudaSupport = true;
    };
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

        boot.kernelPackages = pkgs.linuxPackages_6_18;

        theming.active = "catppuccin-mocha";
        # Runtime theme switching: render every adapter template per palette
        # and install the `theming` switcher + session-start service.
        theming.runtimeSwitching = true;

        system.stateVersion = "23.05";
      };
  };
}
