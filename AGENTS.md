# Agent Guidelines for nix-config

This repository contains NixOS/Home Manager configurations using the
[substrate](../substrate) framework for modular, tag-based configuration management.

## Repository Structure

```
nix-config/
├── flake.nix           # Entry point - imports substrate and modules
├── flake.lock          # Locked dependencies
├── lib/                # Shared utilities (e.g., colors.nix)
├── modules/            # NixOS/Home Manager modules organized by category
├── packages/           # Custom package definitions
└── shells/             # Development shell definitions
```

## External Dependencies

- **substrate**: Core framework at `../substrate` - provides the module system,
  tag-based filtering, and build infrastructure
- **nix-private**: Private configuration at `../nix-private` - contains secrets
  and host-specific private data

## Build and Test Commands

### Building NixOS Configurations

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Switch to new configuration (requires sudo)
sudo nixos-rebuild switch --flake .#<hostname>
```

### Development Shells

```bash
# Enter the hdwlinux development shell
nix develop .#hdwlinux

# Enter other shells (go, rust, typescript, etc.)
nix develop .#<shell-name>
```

### Testing Substrate

Substrate tests are in the separate substrate repository:

```bash
# Run all substrate checks
nix flake check ../substrate
```

## Version Control

This repository uses **Jujutsu (jj)**, not Git. Use `jj` commands:

```bash
jj status          # Show working copy status
jj diff            # Show changes
jj commit -m "msg" # Create a commit
jj new             # Start a new change
jj squash          # Squash changes
```

## Code Style Guidelines

### Nix Language Conventions

1. **Function arguments**: Use `{ lib, config, pkgs, ... }:` pattern
2. **Let bindings**: Place at top of function body, before logic
3. **Attribute access**: Prefer explicit `lib.mkOption` over `with lib; mkOption`
4. **Conditionals**: Use `lib.mkIf` for conditional configuration
5. **Merging**: Use `lib.mkMerge` for combining multiple config blocks

### Module Structure

Modules follow the substrate pattern with `config.substrate.modules.<path>`:

```nix
{
  config.substrate.modules.category.name = {
    tags = [ "tag1" "tag2" ];  # Required tags for this module

    nixos = { lib, pkgs, ... }: {
      # NixOS-specific configuration
    };

    homeManager = { config, lib, pkgs, ... }: {
      # Home Manager configuration
    };

    generic = { };  # Shared configuration (applied to both)
  };
}
```

### Package Definitions

```nix
{ lib, pkgs, ... }:
pkgs.stdenv.mkDerivation {
  name = "package-name";
  version = "1.0.0";

  src = pkgs.fetchurl { /* ... */ };

  # Use standard phases
  installPhase = ''
    runHook preInstall
    # installation commands
    runHook postInstall
  '';

  meta = {
    description = "Package description";
    mainProgram = "binary-name";
    platforms = lib.platforms.linux;
  };
}
```

### Ordering Within Files

1. Function parameters (`{ lib, config, pkgs, ... }:`)
2. Let bindings (local variables, helpers)
3. Options definitions (`options.path = lib.mkOption { ... }`)
4. Config section (`config = { ... }`)

### Naming Conventions

- **Module paths**: lowercase with dots (`desktop.custom.niri`)
- **Options**: camelCase (`hdwlinux.ai.agent.mcpServers`)
- **Tags**: lowercase with colons for hierarchy (`desktop:custom:niri`)
- **Packages**: lowercase with hyphens (`atlas-cli`)

### Comments

- Explain "why" or "how", never "what"
- Document non-obvious configurations
- Use `#` for single-line comments

```nix
# Enable native CPU optimizations for better performance
# NOTE: This sacrifices portability for speed
cmakeFlags = [ "-DGGML_NATIVE=ON" ];
```

## Tag System

Tags control which modules are enabled for hosts/users:

- Simple tags: `"gui"`, `"programming"`
- Hierarchical tags: `"desktop:custom:niri"` (implies `desktop:custom` and `desktop`)
- Meta-tags with implications: `{ "hardware:dell" = [ "laptop" "thunderbolt" ]; }`

Tags are validated at evaluation time. Invalid tags cause build failures.

## Common Patterns

### Conditional Configuration

```nix
config = lib.mkIf cfg.enable {
  programs.foo.enable = true;
};
```

### Option Definitions

```nix
options.hdwlinux.feature = {
  enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable the feature.";
  };
};
```

### Using Theme Colors

```nix
homeManager = { config, ... }:
let
  colors = config.hdwlinux.theme.colors.withHashtag;
in {
  # Use colors.base00, colors.base0E, etc.
};
```

## Important Files

- `flake.nix` - Main entry point, defines hosts, users, tags
- `modules/hosts/` - Host-specific configurations
- `modules/users/` - User-specific configurations
- `packages/` - Custom package definitions
- `shells/` - Development shell definitions
