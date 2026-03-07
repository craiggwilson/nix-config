# HDW Linux (nix-config)

Personal NixOS and Home Manager configuration using the [substrate](../substrate)
framework for modular, tag-based configuration management.

## Overview

This repository contains declarative system configurations for multiple hosts
and users, organized using a tag-based module system. Modules are automatically
included based on tags assigned to hosts and users, enabling flexible
composition of features across different machines.

## Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [Jujutsu (jj)](https://github.com/martinvonz/jj) for version control
- Access to sibling repositories:
  - `../substrate` - Core framework (required)
  - `../nix-private` - Private configuration and secrets (required)

### Enabling Flakes

Add to `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

## Repository Structure

```
nix-config/
├── flake.nix           # Entry point - imports substrate and modules
├── flake.lock          # Locked dependencies
├── lib/                # Shared utilities
│   └── colors.nix      # Theme color definitions
├── modules/            # NixOS/Home Manager modules
│   ├── ai/             # AI tools and agents
│   ├── audio/          # Audio configuration
│   ├── desktop/        # Desktop environments
│   ├── gaming/         # Gaming setup
│   ├── hardware/       # Hardware-specific config
│   ├── hosts/          # Host definitions
│   ├── networking/     # Network configuration
│   ├── programs/       # Application configurations
│   ├── security/       # Security tools
│   ├── theming/        # Visual theming
│   ├── users/          # User definitions
│   └── ...             # Other categories
├── packages/           # Custom package definitions
└── shells/             # Development shell definitions
```

## Quick Start

### Building a Configuration

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.blackflame.config.system.build.toplevel

# Build and switch to new configuration
sudo nixos-rebuild switch --flake .#blackflame
```

### Development Shells

```bash
# Enter the hdwlinux development shell
nix develop .#hdwlinux

# Available shells
nix develop .#go          # Go development
nix develop .#rust        # Rust development
nix develop .#typescript  # TypeScript development
nix develop .#mms         # MongoDB MMS development
```

### Updating Dependencies

```bash
# Update all flake inputs
nix flake update

# Update a specific input
nix flake lock --update-input nixpkgs
```

## Hosts

| Host | Description | User Profile |
|:-----|:------------|:-------------|
| `blackflame` | System76 Serval WS laptop | craig@personal |
| `unsouled` | Dell XPS 15 9520 laptop | craig@work |
| `minimal` | Minimal configuration for testing | - |

## Tag System

Tags control which modules are enabled. Tags are hierarchical and support
implications:

```nix
# Simple tag
"programming"

# Hierarchical tag (implies desktop:custom and desktop)
"desktop:custom:niri"

# Tag with implications
{ "gui" = [ "fonts" "graphics" ]; }
```

### Common Tags

| Tag | Description |
|:----|:------------|
| `gui` | Graphical user interface |
| `programming` | Development tools |
| `desktop:custom:niri` | Niri window manager |
| `gaming` | Gaming support |
| `ai:agent` | AI coding assistants |
| `security:secrets` | Secret management |

## Module Structure

Modules use the substrate pattern:

```nix
{
  config.substrate.modules.category.name = {
    tags = [ "required-tag" ];

    nixos = { lib, pkgs, ... }: {
      # NixOS-specific configuration
    };

    homeManager = { config, lib, pkgs, ... }: {
      # Home Manager configuration
    };

    generic = {
      # Shared configuration (applied to both)
    };
  };
}
```

## External Dependencies

### Substrate

The [substrate](../substrate) framework provides:

- Module tree type system
- Tag-based module filtering
- Host and user configuration types
- NixOS and Home Manager builders
- flake-parts integration

See `../substrate/README.md` for framework documentation.

### nix-private

Private configuration containing:

- Secrets and credentials
- Host-specific private data
- Work-related configurations

## Version Control

This repository uses **Jujutsu (jj)**, not Git:

```bash
jj status          # Show working copy status
jj diff            # Show changes
jj commit -m "msg" # Create a commit
jj new             # Start a new change
jj squash          # Squash changes into parent
jj log             # View commit history
```

## Testing

### Validate Configuration

```bash
# Check flake outputs
nix flake check

# Build without switching (dry run)
nix build .#nixosConfigurations.blackflame.config.system.build.toplevel

# Show what would change
sudo nixos-rebuild dry-activate --flake .#blackflame
```

### Test Substrate

```bash
# Run substrate tests
nix flake check ../substrate
```

## Troubleshooting

### Common Issues

**Flake lock out of date:**
```bash
nix flake update
```

**Substrate not found:**
Ensure `../substrate` exists and contains a valid flake.

**Private config not found:**
Ensure `../nix-private` exists and contains a valid flake.

**Tag validation errors:**
Check that all tags used in modules are defined in `flake.nix` under
`substrate.settings.tags`.

## License

Personal configuration - not intended for general use.
