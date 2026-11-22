# nix-config baseline specifications

These specs describe behavior to preserve when changing this repository. They do not inventory installed software, freeze package pins, or guarantee that a service or device works merely because it is configured. For intentional behavior changes, use an OpenSpec change to update the affected requirements and scenarios alongside the Nix changes.

## Coverage and evidence

| Capability | How to check for drift |
| --- | --- |
| [Configuration foundation](configuration-foundation/spec.md) | Evaluate the named hosts and compare effective work, personal, server, and minimal configurations. Check both selected and unselected features. |
| [Hardware support](hardware-support/spec.md) | Inspect generated options and rules, including disabled and empty inputs. Test actual devices separately. |
| [Security and secrets](security-and-secrets/spec.md) | Evaluate declarations with and without the required capability; use dummy identifiers in fixtures. Never resolve or print credentials to check configuration. |
| [Packages and shells](packages-and-shells/spec.md) | Check flake output availability on supported systems. Build affected outputs and smoke-test shell or CLI behavior when changed. |
| [Desktop sessions and actions](desktop-sessions-and-actions/spec.md) | Inspect session entries, launchers, and generated dispatch rules; exercise shell overrides and failure paths in a desktop session or isolated fixture. |
| [Desktop theming](desktop-theming/spec.md) | Compare system and user options independently, including unselected themes and optional settings. |
| [Networking and DNS](networking-and-dns/spec.md) | Evaluate empty, configured, and duplicate provider lists; exercise provider switching and reset on a disposable connection. |
| [System services](system-services/spec.md) | Compare emitted options and units across selected and unselected hosts; check start and health on an appropriate host if runtime behavior changes. |
| [Network filesystems](network-filesystems/spec.md) | Inspect generated filesystem options and automount defaults without mounting shares. Check reachability and authentication separately. |
| [AI client configuration](ai-client-configuration/spec.md) | Test invalid aliases and inspect rendered configuration using dummy credential references. Exercise provider authentication separately. |
| [AI scheduled tasks](ai-scheduled-tasks/spec.md) | Inspect generated services and timers without starting real tasks; use a harmless fixture to exercise execution. |
| [AI model assets](ai-model-assets/spec.md) | Evaluate generated paths without downloading weights; realize selected assets only if verifying actual downloads. |
| [Program integration](program-integration/spec.md) | Compare profile-specific generated configuration; run the affected program's focused checks where available. |

## Verification workflow

From the repository root, validate the spec documents:

```sh
openspec validate --specs --strict
```

In an environment authorized to resolve the flake inputs, evaluate the configuration surfaces relevant to the change. For example, these commands exercise a work-only setting with positive and negative host cases:

```sh
nix eval --json .#nixosConfigurations.unsouled.config.system.autoUpgrade.enable    # true
nix eval --json .#nixosConfigurations.blackflame.config.system.autoUpgrade.enable  # false
```

For a broader evaluation, run `nix flake check --no-build` and evaluate the affected hosts' toplevel derivation paths, e.g.:

```sh
nix eval --raw .#nixosConfigurations.minimal.config.system.build.toplevel.drvPath
```

The scenarios are review and test targets, not an automated test suite. Some negative cases require a focused module fixture rather than an existing host. Full builds and runtime checks are separate: evaluation cannot establish service health, device behavior, remote access, or whether activation succeeds. Do not apply disk layout definitions as a verification step.

## Intent not established by the baseline

- Session-name collision precedence and the handling of partial theme palettes are not specified.
- Individual keybindings, palette literals, package pins, and host-local inventory are configuration data unless an explicit requirement says otherwise.
