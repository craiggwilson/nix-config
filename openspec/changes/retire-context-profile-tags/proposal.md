# Proposal

## Why

`profile:personal` and `profile:work` group modules by *where they are used* rather than *what they are*, so unrelated concerns (endpoint-management agents, CLI tools, account secrets, mail filters, NAS mounts, editor tweaks) are coupled to one context switch. Tags should describe functional categories and host roles; Craig's work/personal distinctions belong only on Craig-owned configuration. The two context tags should disappear rather than be renamed.

## What Changes

- **BREAKING** Remove `profile:personal` and `profile:work` from the flake tag registry, every module `tags` list, and every in-body `hasTag` check, in this repo and in `nix-private`. No umbrella or synonym tag (e.g. `context:work`, `org:mongodb`, a broad `account:*` family) replaces them.
- Tags remain the only selection mechanism. Reusable modules use functional category tags; `user:craig:work` and `user:craig:personal` are narrowly scoped identity tags for Craig-owned instance configuration only.
- Reusable modules are selected by **category** tags that say what kind of thing they are, never by item names and never by `user:craig` or a work/personal/server marker. A category may have one member today (e.g. `profile:3d-printing` for Bambu Studio). Existing categories are reused where they fit.
- First batch: AWS CLI and the MongoDB tools become two independent functional categories, `profile:cloud-infrastructure` and `profile:database-development`.
- System policy is selected by host tags: `unsouled` gains `role:managed-endpoint` (endpoint-management services, implying `service:cloudflare-warp`) and `service:auto-upgrade`; the identical work/personal sudo policies merge under the existing `role:workstation`.
- Craig-owned work and personal integration/configuration (MCP servers and secrets, model routing, mail filters, NAS mounts, knowledge-base vault, scheduled AI tasks, SSH/AWS account config) lives under `modules/users/craig/` and is selected by `user:craig:work` or `user:craig:personal`. These identity tags are not used by reusable program/service modules. Shared Craig configuration remains under `user:craig`.
- Maskedemail's generic wrapper/helper is reusable under `profile:email-management` with an optional `tokenFile`; only `craig@personal` supplies the Fastmail secret and token path. `craig@work` receives the generic unwrapped CLI and helper without the Fastmail entry. The same category also covers Fastmail MCP and both Craig mail-filter variants.
- Evergreen uses `profile:programming` rather than a one-tool CI category. Craig's work wrapper still requires `user:craig:work` + programming + secrets; Craig personal receives the generic package without work credentials.
- The personal CIFS media-mount module is the explicit NixOS exception to the HM-only identity-leaf rule: `user:craig:personal` is combined with `location:raeford` and `capability:filesystem:cifs`, with no `hostcfg.users` guard.
- Host outputs for `blackflame`, `unsouled`, `wintersteel`, `minimal` keep the same packages, services, mounts and Home Manager files; any difference is recorded, not hidden. Selections do not leak across hosts or users.
- External consumers (`nix-private` substrate modules) migrate in lockstep and are verified by evaluation without printing secret values.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `configuration-foundation`: work automatic upgrades move to a host service tag; adds requirements that context profile tags do not exist, that reusable modules are selected by category tags at the right scope, and that Craig-owned config is selected by Craig's identity and instance.
- `program-integration`: work/personal mail-filter variants become Craig-owned configuration selected by instance instead of `profile:work`/`profile:personal`.
- `security-and-secrets`: equivalent workstation sudo policies are unified under `role:workstation`; server sudo selection is host-role scoped.

## Impact

- `flake.nix` tag registry (new categories and Craig identity leaves listed in design.md D1; two tags removed) and removal of the temporary `instanceProfile` extra argument.
- `modules/users/craig/**`, `modules/hosts/unsouled`, and ~45 modules under `modules/{programs,services,security,ai,desktop,locations,nix}` (mapping in design.md D3).
- `../nix-private/substrate-modules/{aws-cli,code42-aat,ssh,cloudflare,mms-bazel,osquery,kolide}`.
- Existing specs `configuration-foundation` and `program-integration`.
