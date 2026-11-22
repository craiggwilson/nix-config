## MODIFIED Requirements

### Requirement: Profile-gated behavior remains scoped

Work-device automatic upgrades SHALL be selected by the host tag `service:auto-upgrade` and SHALL NOT depend on any user tag. The Raeford games NFS mount SHALL require the Raeford location, NFS capability, and gaming profile tags in the NixOS configuration.

#### Scenario: Work profile enables automatic upgrades

- **WHEN** the `unsouled` configuration, which declares `service:auto-upgrade`, is evaluated
- **THEN** `system.autoUpgrade.enable` SHALL be true with the same flake, schedule, reboot and flag settings as before this change
- **AND** the `blackflame` and `wintersteel` configurations SHALL NOT enable this setting
- **Source:** [upgrade gate](../../../modules/nix/default.nix#L58-L67), [host tags](../../../modules/hosts/unsouled/default.nix#L7-L26)

#### Scenario: Gaming mount is not added to non-gaming profiles

- **WHEN** a NixOS fixture has `location:raeford`, `capability:filesystem:nfs`, and `profile:gaming`
- **THEN** `fileSystems."/mnt/games"` SHALL be configured as an NFS automount
- **AND** a fixture lacking any of those tags SHALL NOT receive that mount from this module
- **Source:** [NFS gate](../../../modules/locations/raeford/filesystems/default.nix#L15-L24), [user profile tags](../../../modules/users/craig/default.nix#L15-L79)

## ADDED Requirements

### Requirement: Context profile tags do not exist

The tag registry SHALL NOT declare `profile:personal` or `profile:work`, and no module selector, in-body tag check, or external substrate module consumed by the flake SHALL reference either tag. No umbrella tag whose meaning is a usage context, employer, or stand-in for a user instance name SHALL replace them.

#### Scenario: Retired tags are rejected

- **WHEN** any host, user, or module declares `profile:personal` or `profile:work`
- **THEN** flake evaluation SHALL fail tag validation

#### Scenario: No residual references

- **WHEN** this repository and `nix-private` are searched for `profile:personal` and `profile:work`, excluding archived OpenSpec history
- **THEN** no references SHALL be found

### Requirement: Reusable modules are selected by category at the right scope

Tags SHALL be the only module selection mechanism. Reusable modules SHALL be selected by tags naming a category of thing (capability, profile, role, service), not by item names, and SHALL NOT require `user:craig` or a work, personal, or server marker. System policy SHALL be selected by host tags; NixOS-scoped configuration SHALL NOT be selected solely by a tag that only user instances declare.

#### Scenario: Endpoint-management services follow the host role

- **WHEN** `unsouled`, which declares `role:managed-endpoint`, is evaluated
- **THEN** Kolide, osquery, Falcon sensor, Code42 AAT and Cloudflare WARP SHALL be configured as before this change
- **AND** `blackflame`, `wintersteel` and `minimal` SHALL NOT configure any of them

#### Scenario: Categories are independently selectable

- **WHEN** a user instance declares `profile:cloud-infrastructure` but not `profile:database-development` (or the reverse)
- **THEN** only the tools of the declared category SHALL be installed for that user

#### Scenario: Programming selects generic Evergreen without work credentials

- **WHEN** `craig@personal` is evaluated with `profile:programming` and without `user:craig:work`
- **THEN** the generic `evergreen` package SHALL be installed
- **AND** the work-only Evergreen credential and composed-config entries SHALL be absent

#### Scenario: Reusable modules ignore identity

- **WHEN** a user other than Craig declares a category tag such as `profile:3d-printing`
- **THEN** the category's tools SHALL be installed for that user without any Craig-owned configuration

#### Scenario: Host outputs are preserved

- **WHEN** `blackflame`, `unsouled`, `wintersteel` and `minimal` are evaluated before and after this change
- **THEN** each host's system package names, systemd service names, `fileSystems` keys, and per-user Home Manager package names and file paths SHALL match
- **AND** any remaining difference SHALL be listed with its reason in the change design before the change is archived

#### Scenario: Secrets are not exposed during verification

- **WHEN** external consumers in `nix-private` are verified by evaluation
- **THEN** verification output SHALL contain only module selection, option names and store paths, and SHALL NOT contain secret values

### Requirement: Craig-owned configuration is selected by identity and instance

Instance-specific Craig-owned Home Manager configuration SHALL use `user:craig:work` or `user:craig:personal` identity-leaf tags. Shared Craig configuration may use `user:craig`; reusable modules SHALL NOT use the identity leaves. The work/personal leaves SHALL be assigned only to the matching Craig user instances. The sole NixOS exception SHALL be the personal CIFS media-mount module, which combines `user:craig:personal` with `location:raeford` and `capability:filesystem:cifs`.

#### Scenario: Work-instance settings stay on the work instance

- **WHEN** `craig@work` is evaluated
- **THEN** its work account settings (for example Grove model routing and work MCP servers) SHALL be selected by `user:craig:work`
- **AND** `craig@personal` and `craig@server` SHALL NOT receive them

#### Scenario: Other users get no Craig configuration

- **WHEN** a user without `user:craig:work` or `user:craig:personal` shares a host with a Craig instance
- **THEN** that user SHALL receive no Craig-owned configuration
- **AND** assigning the same functional category tags to that user SHALL NOT select Craig's account configuration

#### Scenario: Personal CIFS mounts use the documented NixOS exception

- **WHEN** `blackflame` is evaluated with `craig@personal`, `location:raeford`, and `capability:filesystem:cifs`
- **THEN** the personal media mounts SHALL be present
- **AND** `unsouled`, `wintersteel`, and `minimal` SHALL NOT receive those personal media mounts
