# Program integration

## Purpose

Define the baseline behavior of program modules: tag-gated integration into the appropriate configuration surface, shared Flatpak request collection, and separation of profile-specific variants. These specs do not freeze package versions, application inventories, or machine-specific settings.

## Requirements

### Requirement: Program configuration is contributed by selected modules

Program modules SHALL declare selection tags and contribute configuration through their `nixos`, `homeManager`, or `generic` surface. Their effects SHALL be absent when substrate's selection rules do not select them.

#### Scenario: Select a desktop program module

- WHEN a host/user satisfies the declared selection requirements for a desktop program module
- THEN that module contributes its configured desktop program integration

#### Scenario: Do not select an inapplicable program module

- WHEN a host/user does not satisfy a module's declared selection requirements
- THEN that module contributes none of its program configuration

#### Scenario: Preserve configuration-surface boundaries

- WHEN a selected program module defines a NixOS-only setting
- THEN that setting is contributed through the NixOS surface rather than as a Home Manager user setting

### Requirement: Flatpak requests have an empty baseline and accumulate when selected

The shared `hdwlinux.programs.flatpaks` option SHALL default to an empty list and collect identifiers contributed by selected modules. It represents requests, not a guarantee of installation.

#### Scenario: No Flatpak requests are contributed

- WHEN no selected module adds a Flatpak identifier
- THEN `hdwlinux.programs.flatpaks` remains empty

#### Scenario: Selected module requests a Flatpak

- WHEN a selected module contributes a Flatpak identifier
- THEN that identifier is present in the collected list

#### Scenario: Unselected module requests a Flatpak

- WHEN a module that contributes a Flatpak identifier is not selected
- THEN its identifier is absent from the collected list

### Requirement: Profile-specific integrations remain separated

Work- and personal-specific variants SHALL retain their declared tag boundaries and contribute configuration only when selected. Selecting one variant SHALL not implicitly select another.

#### Scenario: Select work mail filters

- WHEN the `user:craig` and `profile:work` tags select the work variant
- THEN the work filter package is contributed

#### Scenario: Select personal mail filters

- WHEN only the `profile:personal` requirement selects the personal variant
- THEN the personal filter package is contributed without selecting the work variant

#### Scenario: Neither profile matches

- WHEN neither work nor personal variant is selected
- THEN neither profile-specific filter package is contributed

### Requirement: Custom program integrations preserve their generated outputs

Custom program modules SHALL preserve their generated integration behavior as well as package selection. Panix SHALL derive fleet entries from eligible hosts; selected Herdr Core configuration SHALL include its user service and linger setting.

#### Scenario: Generate Panix fleet entries

- WHEN a host is not users-only and has users
- THEN it is eligible for a fleet entry, with remote build mode emitted unless its tags select local build mode

#### Scenario: Exclude an ineligible Panix host

- WHEN a host is users-only or has no users
- THEN it is omitted from the generated fleet installables

#### Scenario: Select Herdr Core

- WHEN the `user:craig` tag selects the Herdr Core module
- THEN the user service and configured linger behavior are contributed

## Sources

- [Generic program module and Flatpak option](../../../modules/programs/default.nix#L2-L11)
- [NixOS integration example](../../../modules/programs/dconf/default.nix#L2-L7) · [desktop module tags](../../../modules/programs/obsidian/default.nix#L2-L6)
- [Flatpak request example](../../../modules/programs/bambu-studio/default.nix#L2-L7)
- [Work/personal mail-filter variants](../../../modules/programs/mail-filters/default.nix#L445-L485) · [work-specific model profile tags](../../../modules/ai/clients/models/default.nix#L192-L197)
- [Panix host filtering and build modes](../../../modules/programs/panix/default.nix#L13-L43) · [Panix module integration](../../../modules/programs/panix/default.nix#L70-L92)
- [Herdr Core service and linger](../../../modules/programs/herdr/core.nix#L11-L40)
