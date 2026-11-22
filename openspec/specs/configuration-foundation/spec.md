# Configuration foundation Specification

## Purpose

Define the contracts for selecting host and user configurations through the flake's tag model, including the boundaries that keep host-, location-, and profile-specific behavior out of unrelated configurations.

## Requirements

### Requirement: Supported systems and host identities

The flake SHALL expose four NixOS hosts with their declared systems and SHALL configure the supported system set in its substrate settings.

#### Scenario: Evaluate each declared host

- **WHEN** the four declared NixOS hosts are evaluated
- **THEN** each host SHALL use its declared system and user/profile assignment
- **AND** `wintersteel` SHALL remain `aarch64-linux`, not be evaluated as an x86 host
- **Source:** [flake system set](../../../flake.nix#L173-L182), [minimal](../../../modules/hosts/minimal/default.nix#L6-L13), [blackflame](../../../modules/hosts/blackflame/default.nix#L7-L30), [unsouled](../../../modules/hosts/unsouled/default.nix#L7-L26), [wintersteel](../../../modules/hosts/wintersteel/default.nix#L7-L29)

#### Scenario: Reject unsupported system assumptions

- **WHEN** a host or package output is evaluated for a system outside the configured system set
- **THEN** the baseline SHALL make no promise that the output is available on that system
- **Source:** [configured systems](../../../flake.nix#L173-L182)

### Requirement: Tags select configuration modules

Tags SHALL select modules whose requirements match the effective tag set. Hierarchical and declared hardware-model implications SHALL remain effective.

#### Scenario: Model implications select laptop capabilities

- **WHEN** `blackflame` or `unsouled` is evaluated with its declared hardware-model tag
- **THEN** the effective tag set SHALL include that model's implied capabilities and laptop role
- **AND** capability modules selected by those effective tags SHALL be present
- **Source:** [model tag implications](../../../flake.nix#L339-L365), [host tags](../../../modules/hosts/blackflame/default.nix#L7-L30)

#### Scenario: Minimal host does not inherit workstation configuration

- **WHEN** `minimal` is evaluated with only its declared core and host tags
- **THEN** it SHALL NOT acquire a Craig user profile or the Raeford location configuration
- **AND** location- or desktop-selected options SHALL remain absent unless another selected module explicitly provides them
- **Source:** [minimal tags](../../../modules/hosts/minimal/default.nix#L6-L13), [user profiles](../../../modules/users/craig/default.nix#L15-L79)

### Requirement: Profile-gated behavior remains scoped

Work-only automatic upgrades SHALL require both Craig identity and work profile tags. The Raeford games NFS mount SHALL require the Raeford location, NFS capability, and gaming profile tags in the NixOS configuration.

#### Scenario: Work profile enables automatic upgrades

- **WHEN** the `unsouled` work configuration is evaluated
- **THEN** `system.autoUpgrade.enable` SHALL be true
- **AND** the personal `blackflame` and server `wintersteel` configurations SHALL NOT enable this work-only setting
- **Source:** [upgrade gate](../../../modules/nix/default.nix#L58-L67), [host profiles](../../../modules/hosts/unsouled/default.nix#L7-L26)

#### Scenario: Gaming mount is not added to non-gaming profiles

- **WHEN** a NixOS fixture has `location:raeford`, `capability:filesystem:nfs`, and `profile:gaming`
- **THEN** `fileSystems."/mnt/games"` SHALL be configured as an NFS automount
- **AND** a fixture lacking any of those tags SHALL NOT receive that mount from this module
- **Source:** [NFS gate](../../../modules/locations/raeford/filesystems/default.nix#L15-L24), [user profile tags](../../../modules/users/craig/default.nix#L15-L79)

### Requirement: Location configuration is opt-in

Raeford location modules SHALL require `location:raeford`. Hosts without that tag SHALL NOT receive their location-specific settings.

#### Scenario: Raeford host receives location settings

- **WHEN** a host with `location:raeford` is evaluated
- **THEN** its selected location modules SHALL contribute their declared configuration
- **Source:** [Raeford networking](../../../modules/locations/raeford/networking/default.nix#L2-L19), [printer](../../../modules/locations/raeford/printers/default.nix#L6-L25)

#### Scenario: Unlocated host stays location-neutral

- **WHEN** `minimal` is evaluated
- **THEN** the Raeford modules SHALL NOT add the location domain, host aliases, printer, scanner, or timezone
- **Source:** [minimal tags](../../../modules/hosts/minimal/default.nix#L6-L13), [timezone module](../../../modules/locations/raeford/time/default.nix#L2-L8)
