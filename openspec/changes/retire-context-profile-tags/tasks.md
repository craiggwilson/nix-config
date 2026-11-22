# Tasks

## 1. Audit and baseline

- [ ] 1.1 Search this repo and `../nix-private` for `profile:personal` / `profile:work` in `tags`, `hasTag`, and any other form; reconcile every hit against design.md D4
- [ ] 1.2 Write a small eval script that emits, per host (`blackflame`, `unsouled`, `wintersteel`, `minimal`), system package names, systemd service names, `fileSystems` keys, per-user HM package names and `home.file` keys, plus toplevel drv path for information — names and paths only, no option values
- [ ] 1.3 Capture baselines from the current tree with `--override-input nix-private ../nix-private`

## 2. Registry and instance predicate

- [ ] 2.1 Verify whether a nix-config `settings.extraArgsGenerators` entry can publish `usercfg.profile` to HM modules on both standalone and NixOS-embedded HM paths; if not, stop and report options per design.md D3
- [ ] 2.2 Add the D1 category tags to the `flake.nix` registry (`role:managed-endpoint` implying `service:cloudflare-warp`)

## 3. First batch

- [ ] 3.1 Retag `programs/aws-cli` to `profile:cloud-infrastructure` and `programs/{mongodb,mongodb-tools}` to `profile:database-development`, removing `user:craig` and `profile:work`; add both categories to `craig@work`
- [ ] 3.2 Diff against baseline; confirm each category can be dropped from `craig@work` independently

## 4. Host system policy

- [ ] 4.1 Retag kolide, osquery, falcon-sensor, code42-aat to `role:managed-endpoint` and cloudflare-warp to `service:cloudflare-warp`; add `role:managed-endpoint` to `unsouled`
- [ ] 4.2 Gate autoUpgrade in `modules/nix/default.nix` on `service:auto-upgrade`; add it to `unsouled`
- [ ] 4.3 Merge `security/sudo/{work,personal}` into one module on `role:workstation`
- [ ] 4.4 Switch noctalia/dux warp widgets and package to `hasTag "service:cloudflare-warp"`
- [ ] 4.5 Diff; confirm no set changes on any host

## 5. Craig-owned configuration

- [ ] 5.1 Keep `users/craig/{work,personal}` under `modules/users/craig/`, selected by `user:craig` and the instance predicate instead of the retired tags
- [ ] 5.2 Move AI model routing (personal, craig-work, grove, fireworks), grove-gateway plugin, gws work block and fastmail-mcp enablement under `modules/users/craig/`, by instance, keeping `profile:ai`
- [ ] 5.3 Move mail filters under `modules/users/craig/`, by instance
- [ ] 5.4 Drop the context check from the raeford cifs home mount; move media mounts to the personal instance
- [ ] 5.5 Add a vault option to herdr/noctalia (default `kb`); set `kb-work` from the Craig work instance; move day-plan and morning-brief under Craig, work instance
- [ ] 5.6 Move the vscodium `mms` profile to Craig config, work instance
- [ ] 5.7 Diff all hosts

## 6. Remaining categories

- [ ] 6.1 Retag mongo-orchestration, atlas-cli, kube-cli, evergreen, idea, slack, zoom, jira-cli, slackcli per D4 (no `user:craig`); add categories to `craig@work`
- [ ] 6.2 Retag calibre, freetube, bambu-studio, lilypond, musescore, debussy (program and skill) per D4; add categories to `craig@personal`
- [ ] 6.3 Diff all hosts

## 7. External consumers

- [ ] 7.1 Migrate `nix-private` modules per D4 in lockstep
- [ ] 7.2 Evaluate with `--override-input nix-private ../nix-private` and diff; inspect output to confirm it contains no secret values

## 8. Retire tags and verify

- [ ] 8.1 Remove `profile:personal` and `profile:work` from the `flake.nix` registry and from the Craig user instances
- [ ] 8.2 Confirm a fixture declaring either tag fails tag validation
- [ ] 8.3 Re-run the residual search in both repos (excluding archived OpenSpec); expect zero hits
- [ ] 8.4 Grep reusable modules (outside `modules/users/craig/`) for `user:craig`; expect only pre-existing Craig-owned integrations listed in D4 or none
- [ ] 8.5 Grep NixOS-classed modules for selectors requiring only user-declared categories; expect none
- [ ] 8.6 Final set diff for all four hosts; list any remaining difference with its reason in design.md
- [ ] 8.7 Build all four host toplevels
