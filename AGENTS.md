# AGENTS.md - AI Assistant Guide

## Repository Overview

This is a NixOS/Home Manager configuration repository for personal systems using the **substrate** framework.

### Version Control

**This repository uses Jujutsu (jj), not Git.** Use `jj` commands for all version control operations:

```bash
jj status          # Check current state
jj diff            # View changes
jj new             # Create a new change
jj describe -m ""  # Add a description to the current change
jj squash          # Squash changes into parent
jj log             # View history
jj git push        # Push to remote
```
### Related Repositories

- **`nix-private`** (sibling repository): Contains private/sensitive substrateModules imported via `inputs.hdwlinux-private.substrateModules.nix-private`
- Clone location: `~/Projects/hdwlinux/nix-private`

---

## File Structure

```
nix-config/
├── hdwlinux/           # Active configuration using substrate
│   ├── flake.nix        # Main flake definition
│   ├── modules/         # Substrate modules
│   │   ├── apps/        # Application category definitions
│   │   ├── boot/        # Boot configuration
│   │   ├── desktop/     # Desktop environment (Hyprland, etc.)
│   │   ├── hardware/    # Hardware configurations
│   │   ├── hosts/       # Host-specific configurations
│   │   ├── programs/    # Program configurations
│   │   ├── services/    # System services
│   │   └── users/       # User configurations
│   └── packages/        # Custom package definitions
└── substrate/           # Framework for building NixOS/Home Manager configs
    ├── builders/        # Flake-parts integration
    ├── core/            # Core framework logic
    └── extensions/      # Tags, types, home-manager extensions
```

---

## Substrate Framework

### Core Concepts

Substrate is a framework for building modular NixOS and Home Manager configurations with a tag-based selection system.

#### Module Structure

Modules are defined under `config.substrate.modules.<path>.<name>`:

```nix
{
  config.substrate.modules.programs.example = {
    tags = [ "some-tag" ];  # Required tags to enable this module
    
    nixos = { pkgs, ... }: {
      # NixOS configuration
    };
    
    homeManager = { config, ... }: {
      # Home Manager configuration
    };
  };
}
```

#### Tags System

Tags control which modules are included in a configuration:

- Tags are hierarchical (e.g., `desktop:custom:hyprland` implies `desktop:custom` and `desktop`)
- Hosts and users declare tags; modules require tags to be included
- Use `hasTag` in module functions to conditionally configure based on active tags

#### Hosts and Users

Hosts are defined with associated users and tags:

```nix
substrate.hosts.hostname = {
  system = "x86_64-linux";
  users = [ "username@profile" ];
  tags = [ "host:hostname" ];
};
```

Users can have multiple profiles (e.g., `craig@personal`, `craig@work`).

---

## Code Style Guidelines

### Comments

**Only explain "why", never "what":**

- ✅ Document complex business logic or architectural decisions
- ✅ Explain non-obvious design choices or workarounds
- ✅ Note external dependencies or constraints
- ❌ Do not describe what code does if it's readable
- ❌ Do not add comments for simple/obvious functionality
- ❌ Do not use comments as code documentation for straightforward Nix expressions

### Nix Style

- Use `lib.mkIf` for conditional configuration
- Use `lib.mkOption` with proper types and descriptions for options
- Follow existing patterns in the codebase for consistency

---

## Development Workflow

### Building Configurations

```bash
# Build NixOS configuration
nix build .#nixosConfigurations.hostname.config.system.build.toplevel

# Build Home Manager configuration  
nix build .#homeConfigurations.username.activationPackage

# Run validation checks
nix flake check
```

### Testing Changes

```bash
# Test a new configuration (NixOS)
sudo nixos-rebuild test --flake .#hostname

# Test a new configuration (Home Manager standalone)
home-manager test --flake .#username
```

### Common Patterns

1. **Adding a new program**: Create `hdwlinux/modules/programs/<name>/default.nix` with appropriate tags
2. **Adding a new host**: Create `hdwlinux/modules/hosts/<hostname>/default.nix` with disko config if needed
3. **Adding a new tag**: Add to the `substrate.settings.tags` list in the flake


### Agent Usage

You can consult the **nix-expert** on best nix practices and other types of questions.

---

## Key Files

- `hdwlinux/flake.nix` - Main entry point, imports all modules and defines substrate settings
- `substrate/extensions/tags/default.nix` - Tag system implementation
- `substrate/builders/flake-parts/*.nix` - NixOS and Home Manager configuration builders

