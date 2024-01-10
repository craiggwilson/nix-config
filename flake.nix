{
  description = "HDW Linux";

  inputs = {
    # unstable packages are used by default
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    # also provide stable packages if unstable are breaking
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";
    
    # nix user repository provides additional packages.
    nur.url = github:nix-community/NUR;

     # Generate System Images
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

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

    # nix-flatpak provides declaritive flatpak installation.
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.1.0";

    # nix-hardware helps set up machine configs
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # secrets is a private repository.
    secrets.url = "github:divnix/blank";

    # snowfall-lib provides structure to the flake
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # themes provides simple coloring and templates.
    themes.url = "github:RGBCube/ThemeNix";
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

        permittedInsecurePackages = [
          "electron-25.9.0"
        ];
      };

      overlays = with inputs; [
        nur.overlay
      ];

      homes.users."craig@unsouled".modules = with inputs; [
        nix-flatpak.homeManagerModules.nix-flatpak
      ];

      systems = {
        modules = {
          nixos = with inputs; [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
          ];
        };
      };
    };
}
