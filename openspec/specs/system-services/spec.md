# System Services

## Purpose

Specify shared baseline service configuration and tag-selected optional services. Evidence: [base timeout](../../../modules/services/default.nix#L2), [D-Bus](../../../modules/services/dbus/default.nix#L2), [logind](../../../modules/services/logind/default.nix#L2), [OpenSSH](../../../modules/services/openssh/default.nix#L2), and representative [greetd](../../../modules/services/greetd/default.nix#L2), [Flatpak](../../../modules/services/flatpak/default.nix#L10), [GameMode](../../../modules/services/gamemode/default.nix#L2), [Docker](../../../modules/services/virtualization/docker/default.nix#L2), and [llama.cpp](../../../modules/services/llama-cpp/default.nix#L2) selectors.

## Requirements

### Requirement: Core service configuration SHALL set bounded system and user service stop timeouts

When the core services module is selected, the default system and user systemd manager stop timeout SHALL each be ten seconds.

#### Scenario: Core services are selected

- **WHEN** a host selects the core services module
- **THEN** the evaluated system and user systemd manager configurations set `DefaultTimeoutStopSec` to `10s`
- **Evidence:** [timeout settings](../../../modules/services/default.nix#L4)

#### Scenario: Core services are not selected

- **WHEN** a host does not select the core services module
- **THEN** this module contributes no stop-timeout setting
- **Evidence:** [core selector](../../../modules/services/default.nix#L2)

### Requirement: Core base service modules SHALL configure D-Bus and logind defaults

When their `core:base` modules are selected, D-Bus SHALL be enabled and logind SHALL ignore lid-switch events while on external power.

#### Scenario: Core base service modules are selected

- **WHEN** a host selects the D-Bus and logind modules
- **THEN** D-Bus is enabled and `HandleLidSwitchExternalPower` is `ignore`
- **Evidence:** [D-Bus enablement](../../../modules/services/dbus/default.nix#L5), [logind setting](../../../modules/services/logind/default.nix#L5)

#### Scenario: A core base service module is not selected

- **WHEN** the corresponding module is not selected
- **THEN** that module does not contribute its service setting
- **Evidence:** [D-Bus selector](../../../modules/services/dbus/default.nix#L2), [logind selector](../../../modules/services/logind/default.nix#L2)

### Requirement: The OpenSSH module SHALL enable SSH when selected

The OpenSSH module SHALL enable OpenSSH when selected by `core:ssh`. Otherwise it SHALL contribute no OpenSSH enablement.

#### Scenario: SSH module is selected

- **WHEN** a host selects the OpenSSH module
- **THEN** the evaluated NixOS configuration enables OpenSSH
- **Evidence:** [OpenSSH enablement](../../../modules/services/openssh/default.nix#L5)

#### Scenario: SSH module is not selected

- **WHEN** a host does not select the OpenSSH module
- **THEN** this module does not enable OpenSSH
- **Evidence:** [OpenSSH selector](../../../modules/services/openssh/default.nix#L2)

### Requirement: Optional service modules SHALL remain independently selectable

Optional services SHALL be contributed by their declared selectors, independently of core service defaults. Podman Docker compatibility SHALL be enabled only when Docker is disabled.

#### Scenario: An optional service module is selected

- **WHEN** a host selects one of the representative optional service modules
- **THEN** the corresponding service configuration is present in the evaluated configuration
- **Evidence:** [greetd enablement](../../../modules/services/greetd/default.nix#L7), [Flatpak enablement](../../../modules/services/flatpak/default.nix#L21), [GameMode enablement](../../../modules/services/gamemode/default.nix#L5), [Docker enablement](../../../modules/services/virtualization/docker/default.nix#L5), [llama.cpp unit](../../../modules/services/llama-cpp/default.nix#L63)

#### Scenario: An optional service module is not selected

- **WHEN** a host does not select an optional service module
- **THEN** that module's service configuration is absent
- **Evidence:** [greetd selector](../../../modules/services/greetd/default.nix#L2)

#### Scenario: Docker is not enabled

- **WHEN** Podman is selected and Docker is disabled
- **THEN** Podman's Docker compatibility option is enabled
- **Evidence:** [conditional Docker compatibility](../../../modules/services/virtualization/podman/default.nix#L7)

#### Scenario: Docker is already enabled

- **WHEN** Podman is selected and Docker is enabled
- **THEN** Podman's Docker compatibility option is disabled
- **Evidence:** [conditional Docker compatibility](../../../modules/services/virtualization/podman/default.nix#L7)
