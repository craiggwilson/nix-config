{
  description = "My Home Manager flake";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
    	url = "github:nix-community/home-manager";	
    	inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = {nixpkgs-stable, nixpkgs-unstable, home-manager, ...}: 
  let
    pkgs = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    pkgsStable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };  
    username = "craig";
    system = "x86_64-linux";
  in {
    defaultPackage.${system} = home-manager.defaultPackage.${system};

    # nixosConfigurations = {
    #   playground = nixpkgs.lib.nixosSystem {
    #     inherit system;

    #     modules = [ 
    #       ./hosts/playground/configuration.nix 
    #       home-manager.nixosModules.home-manager {
    #         home-manager.useGlobalPackages = true;
    #         home-manager.useUserPackages = true;
    #         home-manager.users.craig = import ./home-manager/home.nix;
    #       }      
    #     ]
    #   }
    # };
 
    homeConfigurations = {
      ${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { 
          inherit pkgsStable username; 
          homeDirectory = "/home/${username}";
          repoDirectory = "/home/${username}/Projects/github.com/craiggwilson/nix-config";
        };
	      modules = [ ./home-manager/home.nix ];
      };
    };
  };
}
