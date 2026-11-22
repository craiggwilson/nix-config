# Security and secrets Specification

## Purpose

Define the baseline boundaries for secret declarations, credential-provider configuration, SSH, and privileged accounts. Tests and documentation SHALL use dummy identifiers and SHALL NOT resolve, print, or embed secret values.

## Requirements

### Requirement: Secret declarations require the secrets capability

NixOS and Home Manager configurations SHALL fail their module assertions when they declare secretspec entries or scopes without `core:security:secrets`. Configurations with no declarations SHALL pass this guard without requiring the tag.

#### Scenario: Secret declarations are tagged

- **WHEN** a configuration declares one or more secretspec entries or scopes and has `core:security:secrets`
- **THEN** the secrets guard assertion SHALL pass
- **Source:** [NixOS guard](../../../modules/security/secrets-guard/default.nix#L8-L25), [Home Manager guard](../../../modules/security/secrets-guard/default.nix#L28-L45)

#### Scenario: Secret declarations are untagged

- **WHEN** a configuration declares any secretspec entries or scopes without `core:security:secrets`
- **THEN** evaluation SHALL fail with an assertion identifying the declarations and required tag
- **AND** a configuration with no declarations and no tag SHALL NOT fail this assertion
- **Source:** [assertion condition](../../../modules/security/secrets-guard/default.nix#L15-L25)

### Requirement: Secret provider credentials use protected conventional paths

The selected secrets module SHALL use OnePassword as the default provider in NixOS and Home Manager. Provider credentials SHALL use the configured protected roots, and configuration SHALL reference rather than embed resolved values.

#### Scenario: Secrets support is selected

- **WHEN** the secrets capability module is selected
- **THEN** OnePassword SHALL be the default provider in both NixOS and Home Manager
- **AND** the NixOS credential directory SHALL be created with mode `0700` and root ownership
- **Source:** [NixOS provider and protected directory](../../../modules/security/secrets/default.nix#L3-L27), [Home Manager provider](../../../modules/security/secrets/default.nix#L29-L45)

#### Scenario: Secret values are unavailable to baseline checks

- **WHEN** a spec or evaluation check verifies secret declarations
- **THEN** it SHALL use dummy references or inspect declaration metadata only
- **AND** it SHALL NOT resolve or print credential values
- **Source:** [secret declaration example](../../../modules/locations/raeford/secrets/default.nix#L11-L28)

### Requirement: Deployment access is explicit and separately privileged

The deployment account SHALL use its configurable SSH key and SHALL be distinct from the interactive user. Its Nix-daemon and passwordless-sudo privileges SHALL remain scoped to deployment.

#### Scenario: Deployment account is selected

- **WHEN** the base deployment-user module is applied
- **THEN** the `deploy` account SHALL exist with its configured SSH public key, wheel membership, Nix trust, and NOPASSWD sudo rule
- **Source:** [account and key option](../../../modules/security/deploy-user/default.nix#L12-L30), [Nix access and sudo rule](../../../modules/security/deploy-user/default.nix#L32-L51)

#### Scenario: Interactive-user privilege remains separate

- **WHEN** an interactive user is evaluated under the personal, work, or server sudo module
- **THEN** sudo-rs SHALL remain enabled with wheel restriction and password requirement
- **AND** the deploy account's NOPASSWD rule SHALL NOT make the interactive user's commands passwordless
- **Source:** [interactive sudo profiles](../../../modules/security/sudo/personal.nix#L2-L16), [deploy-only sudo rule](../../../modules/security/deploy-user/default.nix#L37-L50)

### Requirement: SSH client defaults avoid implicit forwarding and default host configuration

When the SSH module is selected, Home Manager SHALL enable the SSH agent and managed SSH configuration, disable the upstream default configuration block, and set agent forwarding off for the wildcard host. Location-specific host mappings SHALL exclude the current host.

#### Scenario: SSH defaults are configured

- **WHEN** the SSH module is selected
- **THEN** the agent SHALL be enabled, managed SSH configuration SHALL be enabled, default configuration SHALL be disabled, and wildcard `ForwardAgent` SHALL be false
- **Source:** [SSH options and defaults](../../../modules/security/ssh/default.nix#L10-L45)

#### Scenario: Host-specific mapping excludes self

- **WHEN** a Raeford Home Manager configuration generates SSH aliases
- **THEN** it SHALL include the other configured machines and SHALL NOT generate an alias for the current host
- **Source:** [Raeford host filtering](../../../modules/locations/raeford/ssh/default.nix#L13-L39)
