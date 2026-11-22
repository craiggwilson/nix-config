# Networking and DNS

## Purpose

Specify the baseline network configuration and optional named DNS-provider behavior configured by the networking modules. Evidence: [core networking options and settings](../../../modules/services/networking/default.nix#L3) and [DNS provider schema and behavior](../../../modules/services/networking/dns/default.nix#L3).

## Requirements

### Requirement: The core networking module SHALL provide baseline host networking

When selected, the core networking module SHALL enable NetworkManager with the iwd Wi-Fi backend, enable the firewall, and set DHCP use to true as a default. It SHALL expose the configured domain and LAN CIDR options.

#### Scenario: Core networking module is selected

- **WHEN** a host selects `core:networking`
- **THEN** its evaluated NixOS configuration enables NetworkManager, iwd Wi-Fi, and the firewall, with DHCP enabled by default
- **Evidence:** [network settings](../../../modules/services/networking/default.nix#L24)

#### Scenario: Core networking module is not selected

- **WHEN** a host does not select the core networking module
- **THEN** this module contributes none of those settings
- **Evidence:** [core networking selector](../../../modules/services/networking/default.nix#L16)

### Requirement: DNS providers SHALL be a named, ordered list of supported provider types

The DNS option SHALL accept ordered NextDNS, Cloudflare, and plain provider entries. Each entry SHALL have a unique name. The first provider SHALL be the default; later providers SHALL be selectable by name. A plain provider SHALL have at least one server address.

#### Scenario: Several uniquely named providers are configured

- **WHEN** providers of supported types are configured with unique names
- **THEN** the first configured provider is the default and later providers are available by name
- **Evidence:** [provider ordering](../../../modules/services/networking/dns/default.nix#L65)

#### Scenario: Provider names are duplicated

- **WHEN** two configured providers have the same name
- **THEN** the NixOS configuration assertion fails
- **Evidence:** [unique-name assertion](../../../modules/services/networking/dns/default.nix#L267)

#### Scenario: A plain provider has no servers

- **WHEN** a plain provider is configured with an empty server list
- **THEN** Nix option evaluation rejects the configuration
- **Evidence:** [nonempty plain DNS server list](../../../modules/services/networking/dns/default.nix#L35)

### Requirement: Configured DNS providers SHALL replace per-link DNS and support returning to network DNS

With providers configured, the DNS module SHALL configure resolved, dispatch, and apply behavior. Provider selection SHALL replace per-link DNS; `off` SHALL restore network DNS. An empty provider list SHALL leave DNS-specific configuration absent.

#### Scenario: DNS providers are configured

- **WHEN** the provider list is nonempty
- **THEN** systemd-resolved, the NetworkManager dispatcher, and the DNS apply service are configured
- **Evidence:** [conditional DNS configuration](../../../modules/services/networking/dns/default.nix#L267)

#### Scenario: A named provider is selected

- **WHEN** a configured provider is selected for a link
- **THEN** its DNS servers replace the link's current DNS server list
- **Evidence:** [provider selection contract](../../../modules/services/networking/dns/default.nix#L65)

#### Scenario: Network DNS is selected

- **WHEN** the DNS command selects `off`
- **THEN** the link returns to network-provided DNS
- **Evidence:** [DNS reset contract](../../../modules/services/networking/dns/default.nix#L71)

#### Scenario: Provider list is empty

- **WHEN** the provider list is empty
- **THEN** the DNS-specific resolved, dispatcher, and apply-service configuration is absent
- **Evidence:** [empty-list conditional](../../../modules/services/networking/dns/default.nix#L267)
