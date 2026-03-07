# AGENTS.md - AI Assistant Guide

## Repository Overview

This is a NixOS/Home Manager configuration repository for personal systems using the **substrate** framework.

### Version Control

**This repository uses Jujutsu (jj), not Git. NEVER use `git` commands.**

### Related Repositories

- **`nix-private`** (sibling): Private substrateModules imported via `inputs.hdwlinux-private.substrateModules.nix-private`
- Clone location: `~/Projects/hdwlinux/nix-private`

---

## File Structure

```
nix-config/
├── hdwlinux/            # Active configuration using substrate
│   ├── flake.nix        # Main entry point; defines hosts, users, tags, overlays
│   ├── modules/         # Substrate modules (one default.nix per feature)
│   │   ├── ai/          # AI agent/LLM configuration
│   │   ├── apps/        # Application category definitions
│   │   ├── boot/        # Boot configuration
│   │   ├── desktop/     # Desktop environments (Niri, Hyprland, etc.)
│   │   ├── hardware/    # Hardware-specific configuration
│   │   ├── hosts/       # Per-host configuration and disko layouts
│   │   ├── programs/    # Per-program Home Manager configuration
│   │   ├── services/    # System and user services
│   │   ├── theming/     # Theme options and catppuccin integration
│   │   └── users/       # Per-user NixOS and Home Manager configuration
│   └── packages/        # Custom package derivations
└── substrate/           # Framework library (not user-edited normally)
    ├── builders/        # flake-parts integration
    ├── core/            # Core framework logic
    ├── extensions/      # Tags, types, home-manager extensions
    └── tests/           # Nix-eval-based tests for substrate itself
```

---

## Build Commands

All commands run from `hdwlinux/` (where `flake.nix` lives).

```bash
# Build a NixOS configuration
nix build .#nixosConfigurations.unsouled.config.system.build.toplevel
nix build .#nixosConfigurations.blackflame.config.system.build.toplevel

# Build a Home Manager configuration
nix build .#homeConfigurations."craig@unsouled".activationPackage

# Validate the flake (runs substrate checks)
nix flake check

# Apply NixOS configuration (on the target host)
sudo nixos-rebuild switch --flake .#unsouled

# Apply Home Manager configuration
home-manager switch --flake .#"craig@unsouled"
```

---

## Testing (substrate framework only)

Tests live in `substrate/tests/` and are pure Nix evaluations — no build required.

```bash
# Run all substrate checks
nix flake check substrate/

# Run a single test file directly (fast, no build)
nix eval -f substrate/tests/core/modules-test.nix
nix eval -f substrate/tests/extensions/tags-test.nix
nix eval -f substrate/tests/builders/checks-test.nix

# Available test files:
#   substrate/tests/core/modules-test.nix
#   substrate/tests/core/lib-test.nix
#   substrate/tests/core/hosts-users-test.nix
#   substrate/tests/core/overlays-packages-test.nix
#   substrate/tests/core/finders-test.nix
#   substrate/tests/extensions/tags-test.nix
#   substrate/tests/extensions/home-manager-test.nix
#   substrate/tests/builders/checks-test.nix
```

Tests return `{ allPassed, summary, results }`. Each test has a `check` attribute that must evaluate to `true`.

---

## Substrate Framework

### Module Structure

Every module is a `default.nix` under `hdwlinux/modules/<category>/<name>/`:

```nix
{
  config.substrate.modules.<category>.<name> = {
    tags = [ "required-tag" ];   # All tags must be declared in flake.nix

    nixos = { lib, pkgs, config, hasTag, inputs, ... }: {
      # NixOS system configuration
    };

    homeManager = { lib, pkgs, config, hasTag, inputs, ... }: {
      # Home Manager user configuration
    };

    generic = { lib, ... }: {
      # Options shared across both (use for mkOption declarations)
    };
  };
}
```

### Tags System

- All tags **must** be declared in `hdwlinux/flake.nix` under `substrate.settings.tags`
- Tags are hierarchical: `desktop:custom:niri` implies `desktop:custom` and `desktop`
- Metatags declare implications: `{ "hardware:dell-xps-15-9520" = [ "laptop" "bluetooth" ]; }`
- Use `hasTag "foo"` (injected arg) for conditional config within a module
- `hasTag` uses prefix matching: `hasTag "desktop"` matches `desktop:custom:niri`

### Hosts and Users

```nix
# In flake.nix
substrate.hosts.hostname = {
  system = "x86_64-linux";
  users = [ "craig@work" ];   # Must match substrate.users keys
  tags = [ "host:hostname" ];
};

# In modules/hosts/<hostname>/default.nix
substrate.modules.hosts.${hostname} = {
  tags = [ "host:${hostname}" ];
  nixos = { ... }: { system.stateVersion = "23.05"; };
};
```

Users follow the pattern `name@profile` (e.g., `craig@personal`, `craig@work`).

### Options Pattern

Declare options in the same module that uses them (co-location):

```nix
homeManager = { config, lib, ... }: {
  options.hdwlinux.services.foo = {
    port = lib.mkOption {
      description = "Port for foo service.";
      type = lib.types.int;
      default = 8080;
    };
  };
  config = {
    # use config.hdwlinux.services.foo.port
  };
};
```

---

## Code Style

### Nix Formatting

- Formatter: `nix fmt` (nixfmt-rfc-style). Format before committing.
- Indentation: 2 spaces
- Attribute sets: opening brace on same line, closing on its own line
- Function args: multi-line when more than 2-3 args, trailing `...` always present
- Use `inherit` to avoid repetition: `inherit name version;`

### Naming Conventions

- Module paths mirror directory structure: `substrate.modules.programs.git`
- Options under `hdwlinux.*` namespace (e.g., `hdwlinux.theme`, `hdwlinux.user`)
- Local variables: `camelCase` (e.g., `cfg`, `mcpConfig`, `providerMeta`)
- Package names and tags: `kebab-case`
- Use `cfg` as the conventional alias for the module's own config subtree

### Conditionals

```nix
# Prefer lib.mkIf over if/then/else at the config level
config = lib.mkIf cfg.enable { ... };

# Use lib.optionals for list conditionals
packages = [ pkgs.foo ] ++ lib.optionals (hasTag "gui") [ pkgs.bar ];

# Use lib.optionalAttrs for attrset conditionals
} // lib.optionalAttrs (hasTag "cuda") { cudaSupport = true; }
```

### Comments

- Only explain **why** or **how** when non-obvious — never **what**
- Good: explaining a workaround, a non-obvious override, or an external constraint
- Bad: restating what the code already clearly says
- Inline comments for non-obvious flag choices (see `llama-cpp` GGML_NATIVE example)

### Error Handling

- Use `throw` for unrecoverable configuration errors: `throw "Unknown MCP server type for ${name}"`
- Use `config.assertions` for user-facing validation with clear messages
- Substrate checks (`substrate.settings.checks`) for framework-level validation

### Packages

Custom packages in `hdwlinux/packages/<name>.nix` follow standard `mkDerivation` patterns:

```nix
{ lib, pkgs, ... }:
pkgs.stdenv.mkDerivation {
  inherit name version;
  meta = {
    description = "...";
    license = lib.licenses.unfree;
    mainProgram = "binary-name";
  };
}
```

---

## Common Patterns

### Adding a new program

1. Create `hdwlinux/modules/programs/<name>/default.nix`
2. Set `tags` to the appropriate existing tag(s)
3. Add `homeManager` and/or `nixos` sections as needed

### Adding a new host

1. Create `hdwlinux/modules/hosts/<hostname>/default.nix`
2. Create `hdwlinux/modules/hosts/<hostname>/_disko.nix` if needed
3. Add `substrate.hosts.<hostname>` entry in `flake.nix`
4. Add `"host:<hostname>"` to `substrate.settings.tags` in `flake.nix`

### Adding a new tag

1. Add to `substrate.settings.tags` list in `hdwlinux/flake.nix`
2. Tags with implications use attrset form: `{ "new:tag" = [ "implied-tag" ]; }`
3. All implied tags must also be declared

### Referencing flake inputs in modules

- `inputs` is available as a module argument in both `nixos` and `homeManager` functions
- Prefer `pkgs.<package>` over `inputs.<flake>.packages.${system}.<package>` when the package is available in nixpkgs

---

## Key Files

- `hdwlinux/flake.nix` — Hosts, users, tags, overlays, shells, packages
- `hdwlinux/modules/ai/agent/` — OpenCode/AI agent configuration
- `substrate/extensions/tags/default.nix` — Tag system implementation
- `substrate/builders/flake-parts/` — NixOS and Home Manager config builders
- `substrate/tests/lib.nix` — Test utilities (`runTests`, `evalSubstrate`)

## Agent Usage

Consult the **nix-expert** agent for best practices on Nix expressions, nixpkgs patterns, and NixOS module system questions.
