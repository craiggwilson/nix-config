# Nix Flakes

## Basic flake.nix

```nix
{
  description = "My project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.default = pkgs.hello;
        
        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.go pkgs.gopls ];
        };
      }
    );
}
```

## Input Types

```nix
inputs = {
  # GitHub
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  
  # Git
  myrepo.url = "git+https://example.com/repo.git?ref=main";
  
  # Local path
  local.url = "path:./subdir";
  
  # Flake registry
  home-manager.url = "home-manager";
  
  # Follow another input's nixpkgs
  home-manager.inputs.nixpkgs.follows = "nixpkgs";
};
```

## Output Types

```nix
outputs = { self, nixpkgs, ... }: {
  # Packages
  packages.x86_64-linux.default = ...;
  packages.x86_64-linux.myapp = ...;
  
  # Dev shells
  devShells.x86_64-linux.default = ...;
  
  # NixOS configurations
  nixosConfigurations.myhost = nixpkgs.lib.nixosSystem { ... };
  
  # Home Manager configurations
  homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration { ... };
  
  # Overlays
  overlays.default = final: prev: { ... };
  
  # NixOS modules
  nixosModules.default = { ... };
};
```

## Commands

```bash
# Build default package
nix build

# Run default package
nix run

# Enter dev shell
nix develop

# Update inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Show flake info
nix flake show
nix flake metadata
```

## NixOS with Flakes

```nix
nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./configuration.nix
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.users.myuser = import ./home.nix;
    }
  ];
};
```
