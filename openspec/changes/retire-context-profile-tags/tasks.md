# Tasks

## 1. Audit and baseline

- [x] 1.1 Search this repo and `../nix-private` for `profile:personal` / `profile:work` in `tags`, `hasTag`, and any other form; reconcile every hit against design.md D4
- [x] 1.2 Write a small eval script that emits, per host (`blackflame`, `unsouled`, `wintersteel`, `minimal`), system package names, systemd service names, `fileSystems` keys, per-user HM package names and `home.file` keys, plus toplevel drv path for information — names and paths only, no option values
- [x] 1.3 Capture baselines from the current tree with `--override-input hdwlinux-private ../nix-private`

## 2. Registry and Craig identity leaves

- [x] 2.1 Register `user:craig:work` and `user:craig:personal`, assign each only to its matching Craig user instance, and verify hierarchical parent implication plus tag validation
- [x] 2.2 Add the D1 category tags to the `flake.nix` registry (`role:managed-endpoint` implying `service:cloudflare-warp`)

## 3. First batch

- [x] 3.1 Retag `programs/aws-cli` to `profile:cloud-infrastructure` and `programs/{mongodb,mongodb-tools}` to `profile:database-development`, removing `user:craig` and `profile:work`; add both categories to `craig@work`
- [x] 3.2 Diff against baseline; confirm each category can be dropped from `craig@work` independently

## 4. Host system policy

- [x] 4.1 Retag kolide, osquery, falcon-sensor, code42-aat to `role:managed-endpoint` and cloudflare-warp to `service:cloudflare-warp`; add `role:managed-endpoint` to `unsouled`
- [x] 4.2 Gate autoUpgrade in `modules/nix/default.nix` on `service:auto-upgrade`; add it to `unsouled`
- [x] 4.3 Merge `security/sudo/{work,personal}` into one module on `role:workstation`
- [x] 4.4 Switch noctalia/dux warp widgets and package to `hasTag "service:cloudflare-warp"`
- [x] 4.5 Diff; confirm no set changes on any host
- [x] 4.6 Introduce host `role:server` (registry + `wintersteel`); retag `security/sudo/server.nix` from `profile:server` to `role:server`; diff `wintersteel`

## 5. Craig-owned configuration

- [x] 5.1 Select Craig's work and personal configuration with the matching identity-leaf tags; keep shared Craig configuration selected by `user:craig`
- [x] 5.2 Move AI model routing (personal, craig-work, grove, fireworks), grove-gateway plugin, gws work block and fastmail-mcp enablement under `modules/users/craig/`, by instance, keeping `profile:ai`
- [x] 5.3 Move mail filters under `modules/users/craig/`, by instance
- [x] 5.4 Drop the context check from the raeford cifs home mount; move media mounts to the personal instance
- [x] 5.5 Add a vault option to herdr/noctalia (default `kb`); set `kb-work` from the Craig work instance; move day-plan and morning-brief under Craig, work instance
- [x] 5.6 Move the vscodium `mms` profile to Craig config, work instance
- [x] 5.7 Diff all hosts
- [x] 5.8 Move `programs/maskedemail` and `programs/herdr/core` under `modules/users/craig/`, preserving current selections and surfaces; `locations/raeford/secrets` stays location-owned per D3; diff all hosts
- [x] 5.9 Replace all `instanceProfile` branches in Craig-owned Home Manager modules with `user:craig:work` or `user:craig:personal`, remove the custom `extraArgsGenerators` argument, preserve category prerequisites, and verify work/personal/server plus Alice isolation
- [x] 5.10 Split maskedemail into a reusable `profile:email-management` program module and Craig-personal Fastmail token settings; apply the category to Fastmail MCP and both mail-filter variants; document the generic unwrapped CLI on `unsouled`
- [x] 5.11 Select personal CIFS media mounts with `user:craig:personal` plus location/capability tags, remove the `hostcfg.users` guard, and document the explicit NixOS location-mount exception
- [x] 5.12 Split the personal Home Assistant MCP block into `personal/ai.nix` on `user:craig:personal` + `profile:ai`, leaving sync settings in `personal/default.nix`
- [x] 5.13 Remove `profile:continuous-integration` from Craig's Evergreen wrapper while preserving package-option availability and category independence
- [x] 5.14 Remove unused `homeManager = _:` wrappers from the shared Craig default, work vault/tasks, and personal Fastmail modules; leave unrelated modules untouched
- [x] 5.15 Remove `profile:continuous-integration` from the registry, Craig work tags, and generic Evergreen; select generic Evergreen with `profile:programming` and allow Craig personal to receive it without work credentials

## 6. Remaining categories

- [x] 6.1 Retag mongo-orchestration, atlas-cli, kube-cli, idea, slack, zoom, slackcli per D4 (no `user:craig`); split evergreen and jira-cli: generic package module keeps its category, secrets scopes and account wiring move under `modules/users/craig/work`; add categories to `craig@work`
- [x] 6.2 Retag calibre, freetube, bambu-studio, lilypond, musescore, debussy (program and skill) per D4; add categories to `craig@personal`
- [x] 6.3 Diff all hosts

## 7. External consumers

- [x] 7.1 Replace `instanceProfile` checks in Craig's private AWS, MongoDB SSH, and MMS Bazel configuration with `user:craig:work`; retain programming, SSH, and secrets prerequisites
- [x] 7.2 Evaluate with `--override-input hdwlinux-private ../nix-private` and diff; inspect output to confirm it contains no secret values
- [x] 7.3 Update `flake.lock` to the published migrated `nix-private` revision and verify affected host evaluations without `--override-input`; the default-input evaluation and `unsouled` build match the local-checkout results

## 8. Retire tags and verify

- [x] 8.1 Remove `profile:personal` and `profile:work` from the `flake.nix` registry and from the Craig user instances
- [x] 8.2 Confirm a fixture declaring either tag fails tag validation
- [x] 8.3 Re-run residual searches in both repos (excluding archived OpenSpec) for `profile:personal`, `profile:work`, `profile:continuous-integration`, and `profile:email-aliases`; expect zero hits
- [x] 8.4 Grep reusable program/service modules for Craig identity-leaf tags; expect none outside Craig-owned settings and the explicitly documented private account/location integrations
- [x] 8.5 Grep NixOS-classed modules touched by this change for Craig work/personal leaf tags; expect only the documented personal CIFS location-mount exception. Pre-existing user-selected NixOS patterns elsewhere remain out of scope as recorded in design.md.
- [x] 8.6 Final set diff for all four hosts after the leaf-tag migration; list any remaining difference with its reason in design.md
- [x] 8.7 Build the three x86_64 host toplevels and evaluate `wintersteel`'s toplevel derivation; record the AArch64 builder limitation
