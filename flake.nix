{
  description = "Craig's Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager = {
    	url = "github:nix-community/home-manager";	
    	inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = {nixpkgs, nixpkgs-stable, nixos-hardware, home-manager, disko, ...}: 
  let
    hosts = [{
        name = "playground";
        system = "x86_64-linux";
        users = [ "craig" ];
      }
      {
        name = "ghostwater";
        system = "x86_64-linux";
        users = [ "craig" ];
      }
    ];

    forAllHosts = f: builtins.listToAttrs (builtins.map (host: { name = host.name; value = f host; }) hosts);

    pkgsForSystem = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.nvidia.acceptLicense = true;

      # Allows the use of stable packages with pkgs.stable.<package name>.
      overlays =[ 
        (final: prev: { stable = nixpkgs-stable.legacyPackages.${prev.system}; }) 
      ];
    };

  in {

    nixosConfigurations = forAllHosts (host:
      let
        forAllUsers = nixpkgs.lib.genAttrs host.users;
      in nixpkgs.lib.nixosSystem {
          system = host.system;
          pkgs = pkgsForSystem host.system;
          specialArgs = { inherit nixos-hardware; };
          modules = [ 
            ./hosts/${host.name}/configuration.nix 
            disko.nixosModules.disko
            ./hosts/${host.name}/disco.nix
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                repoDirectory = "/home/craig/Projects/github.com/craiggwilson/nix-config";
              };
              home-manager.users = forAllUsers (username: import ./users/${username}/nixos-home.nix);
            }
          ];
        }
      );

    homeConfigurations = {
      craig = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsForSystem "x86_64-linux";
        extraSpecialArgs = {
          repoDirectory = "/home/craig/Projects/github.com/craiggwilson/nix-config";
        };
	      modules = [ ./users/craig/generic-home.nix ];
      };
    };
  };
}
