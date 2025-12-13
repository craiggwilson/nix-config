# AGENTS.md

This is a NixOS and Home Manager configuration flake for "Half-Dozen Wilson's Linux" (hdwlinux), built using snowfall-lib for structured module organization.

## Project Overview

- **Namespace**: All custom modules, options, and library functions use the `hdwlinux` namespace
- **Framework**: Built on [snowfall-lib](https://github.com/snowfallorg/lib) which provides convention-based directory structure
- **Targets**: NixOS systems (x86_64-linux) and standalone Home Manager configurations

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `flake.nix` | Flake entrypoint with inputs, overlays, and system/home modules |
| `systems/` | NixOS system configurations per architecture/hostname (e.g., `systems/x86_64-linux/blackflame/`) |
| `homes/` | Standalone Home Manager configurations per user (e.g., `homes/x86_64-linux/craig/`) |
| `modules/nixos/` | NixOS-specific modules under `hdwlinux.*` options |
| `modules/home/` | Home Manager modules under `hdwlinux.*` options |
| `lib/` | Custom library functions available as `lib.hdwlinux.*` |
| `packages/` | Custom package derivations available as `pkgs.hdwlinux.*` |
| `shells/` | Development shells invoked via `nix develop .#<name>` |
| `overlays/` | Nixpkgs overlays |

## Tag-Based Enable System

This flake uses a **tag-based conditional enable pattern** instead of simple booleans:

```nix
# In system configuration (systems/x86_64-linux/<hostname>/default.nix)
hdwlinux.tags = [
  "programming"
  "gui"
  "work"
  "networking:tailscale"
];

# In modules, options use tags instead of booleans:
options.hdwlinux.programs.augment = {
  enable = config.lib.hdwlinux.mkEnableOption "augment" [ "programming" "work" ];
};
```

Tags support hierarchical matching (e.g., `"audio"` matches `"audio:production"`). Available tags are defined in `lib/types/default.nix`.

## Module Conventions

### Standard Module Structure

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.<name>;  # or hdwlinux.services.<name>, etc.
in
{
  options.hdwlinux.programs.<name> = {
    enable = config.lib.hdwlinux.mkEnableOption "<name>" "<tag-or-tags>";
    # Additional options...
  };

  config = lib.mkIf cfg.enable {
    # Configuration when enabled
  };
}
```

### Key Patterns

- Use `config.lib.hdwlinux.mkEnableOption` (from module scope) or `lib.hdwlinux.mkEnableOption` (from lib scope) for enable options
- Always guard config with `lib.mkIf cfg.enable`
- Access custom packages via `pkgs.hdwlinux.<package-name>`
- Access library functions via `lib.hdwlinux.<function>`
- NixOS modules pass values to Home Manager via `home-manager.sharedModules`

### Shared Options

Options shared between NixOS and Home Manager are defined in `lib/options/default.nix` as `lib.hdwlinux.sharedOptions`.

## MCP Server Configuration

MCP (Model Context Protocol) servers are defined in Home Manager modules:

```nix
hdwlinux.mcpServers.<server-name> = {
  type = "stdio";  # or "http", "sse"
  command = "command-name";
  args = [ ];
};
```

These are automatically aggregated and written to configuration files for Augment, VSCode, and other tools.

## Code Style

- **Formatter**: `nixfmt-rfc-style` (run via `nix fmt`)
- **Indentation**: 2 spaces
- **Trailing commas**: Use in multi-line lists and attrsets
- **Attribute ordering**: Alphabetize when practical
- **String interpolation**: Use `${...}` syntax, escape with `''${...}` in shell scripts

## Common Commands

```bash
# Format all Nix files
nix fmt

# Check flake validity
nix flake check

# Build the current system (without switching)
sudo nixos-rebuild build --flake .

# Build and switch to new configuration
sudo nixos-rebuild switch --flake .

# Build a specific system
sudo nixos-rebuild build --flake .#<hostname>

# Enter a development shell
nix develop .#<shell-name>

# Show flake outputs
nix flake show

# Update flake inputs
nix flake update

# Update a specific input
nix flake update <input-name>
```

## Helper Commands (when hdwlinux module is enabled)

The `hdwlinux` CLI provides convenience wrappers:

```bash
hdwlinux switch           # Rebuild and switch to new configuration
hdwlinux build            # Build without switching
hdwlinux flake update     # Update flake inputs
hdwlinux develop <name>   # Enter a development shell
```

## Testing & Validation

- Run `nix flake check` before committing to validate the flake
- Run `nix fmt` to ensure consistent formatting
- Test builds with `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel`

## Important Pitfalls

### Tag Matching
- Tags use prefix matching: enabling `"audio"` will match modules requiring `"audio"` OR `"audio:production"` OR `"audio:midi"`
- When requiring multiple tags, pass a list: `[ "programming" "work" ]` means BOTH must be present
- Tags are defined in `lib/types/default.nix` - add new tags there before using them
- Tags cannot be defined in the same module that is guarded by tags. This will result in a cycle.

### Module Scope vs Lib Scope
- Inside modules, use `config.lib.hdwlinux.mkEnableOption` (evaluated per-module)
- In library code or option type definitions, use `lib.hdwlinux.mkEnableOption`

### NixOS vs Home Manager
- NixOS modules go in `modules/nixos/`
- Home Manager modules go in `modules/home/`
- To share data from NixOS to Home Manager, use `home-manager.sharedModules`
- Never import Home Manager modules directly into NixOS modules

### Package Access
- Custom packages in `packages/` are available as `pkgs.hdwlinux.<name>`
- Upstream packages are accessed normally via `pkgs.<name>`
- Stable channel packages are available via `pkgs.stable.<name>`

### Private Configuration
- Secrets and private configuration come from `hdwlinux-private` flake input
- Never commit secrets to this repository
- Use `opnix` for 1Password secret management

## Adding New Modules

1. Create `modules/home/programs/<name>/default.nix` (or appropriate subdirectory)
2. Follow the standard module structure above
3. Add appropriate tags to gate enablement
4. The module is automatically discovered by snowfall-lib

## Adding New Packages

1. Create `packages/<name>/default.nix`
2. Define the derivation with standard nixpkgs patterns
3. Access via `pkgs.hdwlinux.<name>` in modules

## Adding New Systems

1. Create `systems/x86_64-linux/<hostname>/default.nix`
2. Set `hdwlinux.flake` to the flake directory path
3. Set `hdwlinux.tags` to enable desired features
4. Add `disko.nix` for disk partitioning if needed
5. Set `system.stateVersion` appropriately

## Version Control

This repository uses **[Jujutsu (jj)](https://github.com/jj-vcs/jj)** instead of Git for version control operations. While the repository is Git-compatible (hosted on GitHub), prefer `jj` commands over `git` commands.

### Common jj Commands

```bash
# Show status
jj status

# Show log (default shows relevant commits)
jj log

# Create a new change
jj new

# Describe the current change (commit message)
jj describe -m "Add module for X"

# Squash current change into parent
jj squash

# Edit a previous change
jj edit <change-id>

# Push to remote
jj git push

# Fetch from remote
jj git fetch

# Create a bookmark (branch) and push
jj bookmark create <name> -r @
jj git push --bookmark <name>
```

### Key Differences from Git

- **No staging area**: All changes are automatically included in the current change
- **Working copy is a commit**: The working directory is always a commit that can be amended
- **Change IDs vs commit hashes**: jj uses short change IDs (e.g., `kkmpptxz`) that are stable across rebases
- **Automatic rebasing**: Child commits are automatically rebased when parents change

## Commit Guidelines

- Use imperative mood: "Add module for X" not "Added module for X"
- Reference affected hosts/modules in commit messages
- Run `nix fmt` and `nix flake check` before committing
