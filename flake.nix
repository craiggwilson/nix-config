{
  description = "HDW Linux";

  inputs = {
    # unstable packages are used by default
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    # also provide stable packages if unstable are breaking
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";

    # nix user repository provides additional packages.
    nur.url = github:nix-community/NUR;

    # home manager for config files and user installs
    home-manager = {
    	url = "github:nix-community/home-manager";	
    	inputs.nixpkgs.follows = "nixpkgs";
    };

    # disko handles partitioning and applying disk configurations
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-hardware helps set up machine configs
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # snowfall-lib provides structure to the flake
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # stylix provides consistent styling to a number of packages
    stylix.url = "github:danth/stylix";
  };

  outputs = inputs: 
  let 
    lib = inputs.snowfall-lib.mkLib {
      inherit inputs;
      src = ./.;

      snowfall = {
        # access through the modules will be done through hdwlinux and lib.hdwlinux
        namespace = "hdwlinux";
        meta = {
          name = "hdwlinux";
          title = "Half-Dozen Wilsons Linux";
        };
      };
    };
  in 
    lib.mkFlake {

      channels-config = {
        allowUnfree = true;
      };

      overlays = with inputs; [
        nur.overlay
      ];

      homes = {
        modules = with inputs; [
          stylix.homeManagerModules.stylix
        ];
      };

      systems = {
        modules = {
          nixos = with inputs; [
            home-manager.nixosModules.home-manager
            disko.nixosModules.disko
            #stylix.nixosModules.stylix
          ];
        };
      };
    };
}
