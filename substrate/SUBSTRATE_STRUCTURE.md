# Substrate Framework Structure Analysis

## Overview

The substrate framework is a modular NixOS/Home Manager configuration system that uses a tag-based selection mechanism to determine which modules are included in configurations. It's organized around the principle of declarative configuration with hierarchical tagging.

## Core Directories and Files

### 1. Main Configuration Entry Point
- **`hdwlinux/flake.nix`**: The main flake definition that imports all modules and extensions
- This file defines the substrate settings including tags, packages, shells, and overlays

### 2. Substrate Framework Base
- **`substrate/`**: Contains the core framework implementation
  - `builders/`: Integration with flake-parts
  - `core/`: Core module handling logic
  - `extensions/`: Additional feature modules (tags, home-manager, etc.)

## Key Framework Components

### Extensions (Modules)
The extensions directory contains implementations of substrate features:
- **`tags/default.nix`**: Implements the tag-based module selection system
- **`home-manager/default.nix`**: Enables home-manager support 
- **`shells/default.nix`**: Manages shell definitions
- **`jail/default.nix`**: Provides jail.nix integration
- **`types/default.nix`**: Defines additional types

### Core Module Handling
- **`core/modules.nix`**: Handles module tree structure and collection logic
- **`core/hosts.nix`**: Manages host configurations  
- **`core/users.nix`**: Manages user configurations
- **`core/lib.nix`**: Provides utility functions for the framework

## Module Structure and Organization

### Module Definition Format
Modules follow this pattern:
```
substrate.modules.<path>.<to>.<module> = {
  tags = [ "tag1", "tag2" ];
  nixos = { pkgs, ... }: { ... };
  homeManager = { config, ... }: { ... };
}
```

### Hierarchical Tag System
Tags can be hierarchical:
- `desktop:custom:hyprland` implies `desktop:custom` and `desktop`
- Tags are used to conditionally include modules in configurations

### Module Organization by Category
Modules are organized under `hdwlinux/modules/`:
- `apps/`: Application category definitions
- `boot/`: Boot configuration  
- `desktop/`: Desktop environment configurations (Hyprland, etc.)
- `hardware/`: Hardware-specific configurations
- `hosts/`: Host-specific configurations 
- `programs/`: Program configurations
- `services/`: System services
- `users/`: User configurations

## How the Framework Works

1. **Tag-based Selection**: Modules are included based on host/user tags
2. **Host Configuration**: Hosts define system, users, and tags in `modules/hosts/<hostname>`
3. **User Configuration**: Users define their tags in `modules/users/<username>` 
4. **Module Activation**: Only modules with matching tags are included in final configurations

## Example Implementation

**Host Module Example** (`hdwlinux/modules/hosts/blackflame/default.nix`):
```nix
substrate.hosts.blackflame = {
  system = "x86_64-linux";
  users = [ "craig@personal" ];
  tags = [ "host:blackflame" ];
}
```

**Desktop Module Example** (`hdwlinux/modules/desktop/custom/hyprland/default.nix`):
```nix
substrate.modules.desktop.custom.hyprland = {
  tags = [ "gui", "desktop:custom:hyprland" ];
  nixos = { pkgs, ... }: { ... };
  homeManager = { config, ... }: { ... };
}
```

**User Module Example** (`hdwlinux/modules/users/craig/default.nix`):
```nix
substrate.users.craig@personal = {
  tags = [ "users:craig:personal" ];
}
```

This framework enables a highly modular approach where configuration is built dynamically based on tags, making it easy to customize configurations for different hosts and user profiles.