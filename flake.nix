{
  description = "Craig's Nix Flake";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
    	url = "github:nix-community/home-manager";	
    	inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = {nixpkgs-stable, nixpkgs-unstable, home-manager, disko, ...}: 
  let
    system = "x86_64-linux";
    username = "craig";

    pkgs = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      overlays = [ 
        # This overlay allows the use of pkgs.stable.<package name>.
        (final: prev: {
          stable = nixpkgs-stable.legacyPackages.${prev.system};
        }) 
      ];
    };

    # I use mkOutOfStoreSymlink to link back to the repository for certain configuration that _must_ be mutable.
    # As such, I need the repo directory that isn't accessible at runtime due to how flakes work.
    extraSpecialArgs = { 
      repoDirectory = "/home/${username}/Projects/github.com/craiggwilson/nix-config";
    };
  in {
    nixosConfigurations = {
      playground = nixpkgs-unstable.lib.nixosSystem {
        inherit system;
        modules = [ 
          ./hosts/playground/configuration.nix 
          disko.nixosModules.disko
          ./disks/single-disk-full-size-btrfs.nix {
            _module.args.disks = ["/dev/vda"];
          }
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = extraSpecialArgs;
            home-manager.users.${username} = import ./users/${username}/nixos-home.nix;
          }      
        ];
      };
    };
 
    homeConfigurations = {
      ${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = extraSpecialArgs;
	      modules = [ ./users/${username}/generic-home.nix ];
      };
    };
  };
}
