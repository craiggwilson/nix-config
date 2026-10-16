# Tag to Capability Migration Plan

## 0. Ground truth

- Under tags, a module's `tags` mean "load when the host has these" (host-side
  descriptor plus the tag catalogue's implication machinery). Under
  capabilities, a module's `provides` is what it offers (roots select it) and
  its `requires` is a *filter* (admitted only when already required or already
  provided) — `requires` never pulls modules in.
- Hosts and users are the only roots. Their `requires` sets drive everything;
  nothing built during resolution widens them. Prefix selection (`:`
  boundaries) is intrinsic: requiring a bare parent sweeps every `parent:*`
  offer.
- Meta-tags and the implication machinery have no equivalent. Hosts and users
  must name leaf capabilities explicitly in literal `requires` lists.
- `hasTag` (prefix match over the expanded tag set) becomes `hasCapability`
  (exact match over the provided set).
- Current state: 243 modules (203 tagged, 40 untagged), 3 hosts (blackflame ←
  craig@personal, unsouled ← craig@work, minimal ← no users), a tag catalogue
  with two implication layers in `flake.nix`, `hasTag` in 11 files, and a
  dormant branch (`desktop:custom:*`, hyprland, sunshine/`gaming:streaming`)
  that no host selects today.
- Both extensions set `substrate.settings.modulesFinder` unconditionally with
  conflicting values, so coexistence needs
  `substrate.settings.modulesFinder = lib.mkForce "by-tags"` in `flake.nix`
  during the migration. Flip to `"by-capabilities"` in Phase 5 and delete the
  tags import in Phase 6.

## 1. Target vocabulary

### The doctrine

- **provide = identity, require = context.** A module's `provides` answers
  "what subsystem does this belong to"; its `requires` answers "under what
  conditions does this variant belong in the build".
- A *declarer* module (options + services for a subsystem) provides its
  domain cap (`hardware:networking`, `hardware:monitors`, …). A *setter*
  (per-location or per-profile values for those options) provides the same
  domain cap as the declarer it extends — two providers of one capability
  load together — and requires its context (`location:raeford`,
  `profiles:work`).
- Roots therefore name every domain cap they want and every context cap the
  setters gate on. `wants` reads only root requirements, never `provided` —
  a domain cap missing from the roots silently drops the context-scoped
  setter, so the root list is the completeness contract.
- Context caps need a *provider* for the coverage check: one designated
  marker node per location (`locations/raeford/default.nix` provides
  `location:raeford` and carries the location-common system configuration,
  e.g. the timezone).
- Family sweeps survive only where members genuinely share an identity:
  `gui` (graphical stack, compositors excluded), `programming`, `gaming`,
  `ai:clients`, and the `core:*` utilities. Wildcards (`:*` / `:**`) are the
  only sweeps — nothing is implied by a bare parent prefix.

### Principles

- **R1** — Sweep namespaces (`X:` nesting) exist only where the whole family
  should co-locate: `hardware:*`, `ai:clients:*`, `hardware:model:*`,
  `host:<name>`, `desktop:noctalia`. Never require a bare parent whose
  children are optional.
- **R2** — Top-level bare names are category sweeps only; specific features
  nest under the domain that owns them (`networking:tailscale`,
  `networking:dns`, `filesystem:nfs`, `virtualization:docker`,
  `hardware:graphics:nvidia`), staying sweep-safe because no root ever
  requires the bare parent. The rule that makes nesting safe: **a bare
  parent is required by a root only when the sweep is wanted**. Practical
  consequences:
  - never require `hardware:graphics` bare — `hardware:graphics:*` holds the
    optional flavors nvidia and cuda; the base graphics module joins via the
    `gui` family sweep instead;
  - dormant features name themselves for reachability, not for taxonomy:
    `gaming-streaming` stays hyphen-flat because roots DO require bare
    `gaming` and it must stay dormant; old-nested dormant branches
    (`desktop:custom:*`, `audio:midi`) keep their names so nothing that
    requires `desktop:custom`/`audio:production` can accidentally reach them.
- **R3** — User flavors are `profiles:personal` / `profiles:work` (matches
  what nix-private already declares modulo its old `profile:*` spelling;
  reconciled later, out of scope here).
- **R4** — Host identity stays `host:<name>` (self-provided by each host
  module; needed by `locations/raeford/ssh`'s machine checks).
- **R5** — Dormancy = a module simply does not offer a capability a root's
  requirement selects. Compositors never offer `gui` — they only offer
  their `desktop:<de>:<wm>` pair leaf — so a future `desktop:custom:hyprland`
  cannot be dragged in by the family sweep; it stays dormant until a host
  requires that leaf.
- **R6** — Option-declaration convention: a module that declares options
  provides a capability for them; modules that set those options `requires`
  it — superseded for co-located per-context setters by the doctrine above
  (they *provide* the domain cap instead, with the context as `requires`).
- **R7** — `core` = minimal cross-class utilities and option-declaring
  interfaces that make sense in nixos, home-manager, and/or darwin. No
  aggregator, no bare `core`; roots name the core families they need
  specifically. Platform maintenance lives in the hardware domain.

### Family-cap convention

A co-location family (things that load together wherever a root asks for the
family) shares one capability: every member **offers** it and the root
**requires** it — `gui` for the graphical stack (compositors excluded, see
R5), `programming` for dev tools, `gaming`, `ai:clients` for the AI client
family, `desktop:noctalia` for Noctalia shell widgets. A member's own
identity leaf is provided in addition for targeting and `hasCapability`,
but the family sweep is what pulls it in.

### Root requires lists (literal, committed)

| Root | requires |
|---|---|
| craig@personal | `users:craig profiles:personal ai:clients ai:image ai:llm audio:production cloud:sync desktop:noctalia:niri gui flatpaks gaming networking:tailscale virtualization:podman programming security:passwordmanager security:secrets theming:catppuccin video:production hardware:yubikey` |
| craig@work | `users:craig profiles:work ai:clients cloud:sync desktop:noctalia:niri gui filesystem:envfs virtualization:docker programming security:passwordmanager security:secrets theming:catppuccin video:production hardware:yubikey` |
| blackflame | `host:blackflame hardware:model:system76-serval-ws hardware:audio hardware:bluetooth hardware:camera hardware:graphics:nvidia hardware:graphics:cuda hardware:laptop hardware:monitors hardware:networking hardware:thunderbolt hardware:printing hardware:scanning boot:systemd networking:dns location:raeford core:home core:interfaces core:nix core:networking core:security core:session core:ssh core:systemd core:utils core:xdg hardware:firmware hardware:power hardware:storage` |
| unsouled | same, `hardware:model:dell-xps-15-9520`, without `networking:dns` |
| minimal | `host:minimal core:ssh core:interfaces` — deliberately lean |

Notes: `gui` is the family sweep of the graphical stack (fonts, graphics
base, desktop base, monitors — the compositors are *not* members, they join
via their `desktop:<de>:<wm>` pair leaf). `hardware:graphics:*` holds nvidia
and cuda, so `hardware:graphics` bare is never required (see R2).
`core:networking` collects the networking utilities (dnsutils, inetutils,
the wifi subcommands and the former core:utils:network members);
`hardware:networking` is the nixos-level services/options. `core:security`
currently holds the sudo pair (each gated on its profile) — polkit stays in
`core:session`; minimal does not require it (nothing there satisfies
coverage). User requirements are automatically unioned into each host's
required set, so user-scoped capabilities stay in the user lists.

Notes: `core:utils` sweeps its `core:utils:*` children — fastfetch rides the
family (there is no `core:diagnostics`). Guide for `gui`: it is the family
sweep of the graphical stack (fonts, graphics base, desktop base, monitors —
the compositors are *not* members, they join via their
`desktop:<de>:<wm>` pair leaf). `hardware:graphics:*` holds nvidia and cuda,
so `hardware:graphics` bare is never required (see R2). User requirements
are automatically unioned into each host's required set, so user-scoped
capabilities stay in the user lists.

### Core layout

Core = minimal utilities and option-declaring interfaces that make sense in
nixos, home-manager, and/or darwin. No aggregator; every root names what it
needs specifically.

| capability | members |
|---|---|
| `core:utils` | programs: coreutils, tree, zip, procps, dconf, fastfetch |
| `core:networking` | core/networking (dnsutils, inetutils, wifi subcommands), programs: pciutils, usbutils, lshw, bandwhich |
| `core:nix` | modules/nix, programs/nh, modules/flake, programs/hdwlinux |
| `core:ssh` | services/openssh, security/ssh (system daemon + HM agent/config), locations/raeford/ssh (machine list, gated on location:raeford + users:craig) |
| `core:session` | greetd, dbus, logind, security/polkit |
| `core:security` | security/sudo personal + work (each requires its profile) — hosts require it; minimal does not |
| `core:systemd` | services/default (systemd Manager timeouts) |
| `core:xdg` | modules/xdg |
| `core:home` | programs: home-manager, bash |
| `core:interfaces` | option declarers: modules/apps, modules/theming, modules/programs, hardware/outputProfiles, modules/users |

Platform maintenance lives in the hardware domain (selected explicitly by
the desktop hosts, out of scope for minimal):

| capability | members |
|---|---|
| `hardware:storage` | services/udisks2, filesystems/gvfs, programs/appimage |
| `hardware:power` | services: upower, powertop, bpftune, irqbalance, system76-scheduler |
| `hardware:firmware` | services/fwupd, hardware/redistributableFirmware |

Not in core: minder is a brainstorming application (not a core utility) —
it becomes `apps:minder`, dormant unless a root names it (under tags it
loaded everywhere as an untagged module).

### Locations under the doctrine

One marker node per location provides the context cap and carries the
location-common configuration; every other location module provides its
domain identity and requires the context. Example (raeford):

| module | provides | requires |
|---|---|---|
| locations/raeford (marker) | `location:raeford` | — ; nixos time.timeZone |
| locations/raeford/monitors | `hardware:monitors` | `location:raeford` |
| locations/raeford/networking | `hardware:networking` | `location:raeford` |
| locations/raeford/outputProfiles | `core:interfaces` | `location:raeford` |
| locations/raeford/printers | `hardware:printing` | `location:raeford` |
| locations/raeford/scanners | `hardware:scanning` | `location:raeford` |
| locations/raeford/filesystems | `filesystem:nfs` | `location:raeford` |
| locations/raeford/ssh | `core:ssh` | `location:raeford`, `users:craig` |

### Directory renames made by the vocabulary

- `hardware:printing` / `hardware:scanning` / `hardware:yubikey`
  (hardware-flavored machine/user features live in the hardware domain).
- `profiles:personal` / `profiles:work` (plural, user workstation flavours).
- `apps:flatpak` (a specific application source cannot be a top-level
  name: top-level bare names are category sweeps only).
- `video:v4l2loopback` — the kernel module provides both
  `video:v4l2loopback` and the `video:production` family cap, which is what
  co-locates it with OBS; solo v4l2loopback can be required directly.

### Module translation rules (per batch)

1. `tags = [X]` → `provides = [new(X)]`.
2. `tags = [A B]` (AND, e.g. gamescope `[gui gaming]`, raeford/ssh
   `[raeford users:craig]`) → `provides = [more-specific]`,
   `requires = [the others]` (e.g. `provides = [gaming]; requires = [gui]`).
3. Untagged → `provides = [namespace cap]`.
4. Modules setting options declared elsewhere → `requires` those (R6); pure
   sweep-family membership needs nothing extra.
5. No self-guards anywhere: if a sweep pulls an unwanted module at flip time,
   the *name* is wrong — re-examine per R2, never bandage with
   `requires = [X]`.

### hasTag → hasCapability call-site map

| hasTag | hasCapability | Files |
|---|---|---|
| `users:craig:work` | `profiles:work` | desktop/noctalia, nix, programs/vscodium ×2 |
| `graphics:nvidia` | `hardware:graphics:nvidia` | services/llama-cpp |
| `networking:tailscale` | `networking:tailscale` | desktop/noctalia |
| `audio` | `hardware:audio` | users/craig |
| `networking` | `hardware:networking` | users/craig |
| `virtualization:docker` | `virtualization:docker` | users/craig |
| `gui`, `programming`, `gaming`, `security:passwordmanager`, `host:<m>` | unchanged | yubikey, 1password, users/craig, locations/raeford |

Every queried name must be an exact `provides` entry of some included module —
audited per batch.

## 2. Phases

jj commit per unit; eval checkpoints throughout.

- **Phase 0 — Baselines.** Capture
  `nix eval .#nixosConfigurations.{blackflame,unsouled,minimal}.config.system.build.toplevel.drvPath`
  into `/tmp/opencode/caps/`. A compare script re-runs this after every
  checkpoint. Confirm the locked substrate has the capabilities extension.
- **Phase 1 — Coexistence scaffold.** Import `substrateModules.capabilities`
  next to `tags`; set `substrate.settings.modulesFinder = lib.mkForce
  "by-tags";`. Gate: all baselines unchanged (proves mkForce precedence works,
  selection untouched). If the module system still errors, fall back to a
  one-line substrate `mkDefault` patch in both extensions.
- **Phase 2 — Roots.** Rewrite `modules/hosts/*` and `modules/users/craig/*`:
  add `requires` lists per the tables above, add
  `provides = [ host:<name> ]` on host modules, `provides = [ users:craig |
  profiles:personal | profiles:work ]` on user modules. Gate: by-tags evals
  unchanged.
- **Phase 3 — Module batches, small→large:** boot → filesystems → networking
  → locations → security → hardware → services → virtualization →
  theming/xdg/fonts → apps/flake/users → ai → desktop → programs (~120 files,
  last). Per batch: apply translation rules, keep old `tags` untouched. Gate
  after every batch: all baselines identical.
  Periodic probes between batches: flip `mkForce` to `"by-capabilities"`, eval
  (expect partial configs, `capability-resolution` errors, and the
  `unused-modules` list as a progress dashboard), flip back. Probe builds stay
  eval-only while half-migrated.
- **Phase 4 — `hasTag` → `hasCapability`.** 11 files per the map. Both
  generators exist while tags+caps coexist. Gate: baselines unchanged.
- **Phase 5 — Flip.** `modulesFinder = lib.mkForce "by-capabilities"`. Fix
  resolution errors and selection drift (suspected cause: sweep regressions
  R2 misses). Gate for moving on: all toplevels eval clean and equal to
  baseline, then one real `nix build` of all three toplevels. No switch —
  the host switch is run manually.
- **Phase 6 — Cleanup.** Remove the `tags` import, the `tags.options`
  catalogue (~145 lines in `flake.nix`), every `tags = [...]` attr, and the
  mkForce layer. Then `nix flake check`. Update this repo's AGENTS.md.
  Optional dedup sweep of dormant-offering aliases.

### Flip findings (phase-5 prep, from the by-caps probe)

- Substrate builds the nixos host from TWO finder contexts: a host-only
  one (`[hostcfg]`, no user requirements) and a host+users one for each
  user's nixos bits. Host-only contexts cannot satisfy profile-gated
  providers, so capabilities whose providers are profile-gated (e.g.
  `core:security`) must be required by the *users*, not the hosts.
- Bare-parent requirements are safe after the substrate wildcard change
  (exact match only; `:*` / `:**` sweep explicitly) — hosts require bare
  `hardware:graphics`; R2's "never require a bare parent" applies to
  wildcard-free sweeps only in the parentFörst-old prefix world and is
  retired except for wildcard requirements themselves.
- `hardware:graphics:cuda` is provided by the nvidia module (CUDA ships
  with the stack).
- nix-private speaks the OLD vocabulary (`profile:work`, option-cap
  requires like `services:code42-aat`). The flip needs at least: rename
  `profile:work` → `profiles:work` in nix-private provides, and our
  option-declarer modules must carry the exact caps nix-private demands
  (code42-aat already does: `services:code42-aat`).
- minimal's by-caps eval succeeded but produced a different drvPath than
  the by-tags baseline (`pwhp78…` vs `fgjk7f…`) — expected drift to triage
  at the flip (minimal's rootless modules).
- unsouled by-caps failed until the fixes above + the code42 option cap;
  re-probe after nix-private reconciliation.

### Out of scope (later)

- Consumer-side `requires` hardening (R6 expansion for remaining
  option-consumers).
- Name polish once the capability-resolution warnings settle.
