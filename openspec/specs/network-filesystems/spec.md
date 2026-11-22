# Network Filesystems

## Purpose

Specify how configured CIFS and NFS mounts are translated into NixOS mount and automount configuration. Evidence: [CIFS mount option generation](../../../modules/services/cifs/default.nix#L8) and [NFS mount/automount generation](../../../modules/services/nfs/default.nix#L8).

## Requirements

### Requirement: CIFS mount declarations SHALL produce CIFS filesystem entries

Each configured CIFS mount SHALL map its local and remote paths to a CIFS entry. Ownership SHALL use the declared user/group. A credentials file SHALL replace inline username; file/directory modes SHALL be `0600`/`0700`.

#### Scenario: A CIFS mount is configured

- **WHEN** a mount declaration supplies local/remote paths, owner, group, and credentials
- **THEN** the NixOS configuration contains a CIFS filesystem entry with the declared endpoints and ownership
- **Evidence:** [CIFS entry generation](../../../modules/services/cifs/default.nix#L78)

#### Scenario: A credentials file is configured

- **WHEN** the mount declaration supplies a non-null credentials-file path
- **THEN** the generated mount options reference that file rather than the inline username
- **Evidence:** [credentials selection](../../../modules/services/cifs/default.nix#L60)

#### Scenario: No CIFS mounts are configured

- **WHEN** the CIFS mount list is empty
- **THEN** the module generates no CIFS filesystem entries
- **Evidence:** [mount list mapping](../../../modules/services/cifs/default.nix#L78)

### Requirement: CIFS automount behavior SHALL follow the mount's `auto` setting

CIFS mounts SHALL default to automount. Enabled mounts SHALL use systemd automount/noauto options and a 600-second idle timeout; disabled mounts SHALL omit them.

#### Scenario: CIFS `auto` is omitted

- **WHEN** a CIFS mount is configured without an `auto` value
- **THEN** it receives the automount options and 600-second idle timeout
- **Evidence:** [`auto` default and generated options](../../../modules/services/cifs/default.nix#L10)

#### Scenario: CIFS `auto` is false

- **WHEN** a CIFS mount sets `auto = false`
- **THEN** it does not receive systemd automount, noauto, or idle-timeout options
- **Evidence:** [conditional automount options](../../../modules/services/cifs/default.nix#L70)

### Requirement: NFS mount declarations SHALL produce mount units

Each configured NFS mount SHALL produce a systemd mount unit. NFS SHALL be supported and rpcbind enabled. Automount defaults off; `auto = true` SHALL produce a 600-second automount.

#### Scenario: An NFS mount is configured

- **WHEN** an NFS mount declaration supplies a remote path and local mountpoint
- **THEN** the system configuration contains the corresponding NFS mount unit
- **Evidence:** [NFS mount generation](../../../modules/services/nfs/default.nix#L38)

#### Scenario: NFS `auto` is omitted or false

- **WHEN** an NFS mount omits `auto` or sets it to false
- **THEN** the mount unit is present but no corresponding automount unit is generated
- **Evidence:** [`auto` default and automount filter](../../../modules/services/nfs/default.nix#L18)

#### Scenario: NFS `auto` is true

- **WHEN** an NFS mount sets `auto = true`
- **THEN** a corresponding automount unit is generated with a 600-second idle timeout
- **Evidence:** [NFS automount generation](../../../modules/services/nfs/default.nix#L47)

#### Scenario: No NFS mounts are configured

- **WHEN** the NFS mount list is empty
- **THEN** no NFS mount or automount units are generated
- **Evidence:** [NFS mount and automount mappings](../../../modules/services/nfs/default.nix#L38)
