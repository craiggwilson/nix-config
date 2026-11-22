# Hardware support Specification

## Purpose

Specify the selection and conditional-configuration contracts for hardware capabilities and display/audio options. These requirements describe generated configuration; they do not assert that a physical device works.

## Requirements

### Requirement: Hardware support is selected by capability and model tags

Hardware modules SHALL be selected through their declared capability, role, or model tags. Unselected modules SHALL NOT add their configuration.

#### Scenario: Audio-capable host enables PipeWire

- **WHEN** a host's effective tags include `capability:audio`
- **THEN** the audio module SHALL enable PipeWire with ALSA, PulseAudio compatibility, and WirePlumber
- **AND** it SHALL force the legacy PulseAudio service off
- **Source:** [audio module](../../../modules/hardware/audio/default.nix#L6-L39), [tag implications](../../../flake.nix#L339-L365)

#### Scenario: Host without audio selection does not receive this audio module

- **WHEN** a host has neither `capability:audio` nor a model tag implying it
- **THEN** this repository's audio module SHALL NOT enable PipeWire or rtkit for that host
- **Source:** [audio module selection](../../../modules/hardware/audio/default.nix#L6-L21)

### Requirement: Noise suppression creates parallel per-microphone sources only when configured

Noise-suppression rules SHALL be emitted only when noise suppression is enabled and the microphone list is non-empty. Each listed microphone SHALL receive a separate rule whose filter input targets that exact microphone and whose output is a parallel audio source; the raw microphone SHALL remain available.

#### Scenario: Enabled microphones get isolated virtual sources

- **WHEN** noise suppression is enabled with one or more microphone node names
- **THEN** the WirePlumber rules SHALL contain one matching filter rule per configured microphone
- **AND** each filter SHALL target its matching microphone and publish an `Audio/Source`
- **AND** the raw source SHALL NOT be hidden or replaced
- **Source:** [per-microphone rule](../../../modules/hardware/audio/filters/default.nix#L6-L59), [host example](../../../modules/hosts/blackflame/default.nix#L80-L85)

#### Scenario: Disabled or empty configuration emits no rules

- **WHEN** noise suppression is disabled, even if microphone names are present
- **THEN** the module SHALL NOT emit its WirePlumber configuration
- **WHEN** noise suppression is enabled with an empty microphone list
- **THEN** the module SHALL NOT emit its WirePlumber configuration
- **Source:** [options and emission gate](../../../modules/hardware/audio/filters/default.nix#L62-L97)

### Requirement: NVIDIA PRIME offload requires both PCI bus identifiers

The NVIDIA module SHALL configure the NVIDIA driver and blacklist nouveau when selected. It SHALL configure PRIME offload bus identifiers only when both the integrated and NVIDIA graphics-card bus IDs are non-empty; incomplete data SHALL NOT produce a partial PRIME configuration.

#### Scenario: Both graphics devices are identified

- **WHEN** both graphics-card bus IDs are configured
- **THEN** the module SHALL expose PRIME offload settings with converted Xorg bus identifiers
- **Source:** [NVIDIA module](../../../modules/hardware/graphics/nvidia/default.nix#L19-L52), [graphics-card type](../../../lib/types.nix#L76-L98)

#### Scenario: Either bus identifier is missing

- **WHEN** either graphics-card bus ID is empty
- **THEN** the module SHALL NOT emit its PRIME offload configuration
- **Source:** [bus-ID condition](../../../modules/hardware/graphics/nvidia/default.nix#L25-L30, ../../../modules/hardware/graphics/nvidia/default.nix#L43-L51)

### Requirement: DisplayLink behavior depends on an explicitly configured DisplayLink monitor

DisplayLink driver and recovery settings SHALL require a configured monitor marked `displaylink = true`. Capability selection alone SHALL NOT add those conditional settings.

#### Scenario: Configured DisplayLink monitor is present

- **WHEN** any configured monitor has `displaylink = true`
- **THEN** the NixOS configuration SHALL include the DisplayLink driver, resume restart, and bounded stop timeout
- **Source:** [monitor option](../../../modules/hardware/monitors/default.nix#L21-L60), [conditional settings](../../../modules/hardware/graphics/displaylink/default.nix#L12-L33)

#### Scenario: No configured monitor uses DisplayLink

- **WHEN** every configured monitor has `displaylink = false`, or no monitors are configured
- **THEN** the DisplayLink-specific driver and recovery settings SHALL NOT be added by this module
- **Source:** [Raeford DisplayLink monitor](../../../modules/locations/raeford/monitors/default.nix#L29-L36)

### Requirement: EDID overrides are conditional and recoverable

The monitor module SHALL generate EDID handling only for configured overrides and SHALL limit runtime override attempts to connected matching connectors with missing or short EDID.

#### Scenario: Override configured for a connected monitor with missing or short EDID

- **WHEN** an override is configured and a matching connector is connected with no EDID or an EDID shorter than 128 bytes
- **THEN** the generated script SHALL attempt the configured override during its boot/resume invocation
- **Source:** [EDID option schema](../../../modules/hardware/monitors/default.nix#L7-L19), [runtime checks](../../../modules/hardware/monitors/default.nix#L132-L177)

#### Scenario: No override or valid EDID

- **WHEN** no monitor has an override, the connector is disconnected, or its EDID is at least 128 bytes
- **THEN** the override path SHALL NOT be applied to that connector
- **Source:** [EDID generation gate](../../../modules/hardware/monitors/default.nix#L78-L90), [runtime checks](../../../modules/hardware/monitors/default.nix#L137-L159)
