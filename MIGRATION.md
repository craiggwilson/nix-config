# home-manager removal — migration state

Goal: replace home-manager with the `perUser` substrate class (see
`extensions/per-user/README.md`). HM stays wired in until the final wave;
each module file migrates whole (homeManager block -> perUser block, never
both active on the same paths).

Status legend: [x] migrated · [ ] pending · (~) blocked/needs decision

## Done (pilot wave)

- [x] Extension scaffold: schema / eval / to-nixos / wrap helpers
- [x] modules/programs/bat — files + packages
- [x] modules/programs/lsd — files + packages
- [x] modules/services/playerctld — packages + service
- [x] modules/desktop/custom/wlsunset — service
- [x] helper injection (merged `lib`) verified end-to-end

## Wave 2 — rename-only (custom `hdwlinux.*` option contributions) — 78 files left

Blocks that only contribute `hdwlinux.ai.*`, `hdwlinux.app`, `hdwlinux.theme`
option values or read them. They keep working under HM scope, but must gain
`perUser` duplicates (or move declarations) before their consumers migrate:

- modules/ai/clients/{agents,commands,rules,skills,mcp-servers,models}/* (~60 files)
- modules/apps/default.nix (generic + homeManager option decls)
- modules/theming/default.nix + theming/catppuccin (theme option decls —
  perUser needs its own `options.hdwlinux.theme.*` block; runtime theming
  itself is a later, nati-shaped feature)
- modules/users/craig/default.nix (hdwlinux.user, secrets decls)

## Wave 3 — packages-only (37 files) — DONE

`home.packages` -> `packages` (homeManager -> perUser class key). Files with
ANY other hm content (services.hypridle, programs.git.settings, hdwlinux.*
contributions) correctly held back: ripgrep, reaper, audioctl, clipboard,
nautilus, screenctl, noctalia*, hyprland-adjacent, apps, networking, flake.
`scripts/per-user-audit.py` guards against silent-loss leftovers (run after
each wave). eval.nix now reuses the host's configured pkgs when
usercfg.system == hostcfg.system (fixes unfree packages like lmstudio).

## Wave 3.5 — git cluster (git, delta, difftastic, mergiraf, gh, gh-dash) — DONE

Multi-module option pattern proven: hdwlinux.programs.git.configFragments
(listOf attrs, folded recursiveUpdate -> generators.toGitINI) as ONE
perUser-owned option in the git module, appended by delta/difftastic/mergiraf/gh.
users/default.nix gained a perUser block declaring hdwlinux.user + id_rsa.pub;
users/craig sets hdwlinux.user in BOTH scopes during coexistence.
Parity vs live HM-rendered files verified (git config/ignore/attributes/
allowed_signers, gh config.yml, gh-dash config.yml, gh extensions linkFarm).
Intentional fix: aliases were nested under settings (rendered [aliases]) ->
now [alias], which is what git actually reads.
gh account-migration activation step (hm) intentionally not ported; re-add
as a oneshot only if a hosts.yml v1->v2 migration is ever needed.

## Wave 4 — config files (mixed files still carrying home.packages ~40 + cfg)

`xdg.configFile` / `home.file` -> `files`. Check per program whether
XDG default suffices (prefer) or `wrap`/`wrap` is needed:

- desktop: niri, noctalia/niri, waybar, hyprlock, shikane, syshud,
  electron-support, hyprland, custom/hyprpaper (settings via service args)
- programs: git (GIT_CONFIG_GLOBAL or files), gh, ssh, zellij, ghostty,
  yazi, helix, rclone (runtime-writable? — see nati criterion: NOT a wrap
  candidate, needs hybrid), opencode, herdr, browserctl, augment, claude-code
- services: cloudflare-warp, llama-cpp, kdeconnect

## Wave 5 — services + env + activation

hm `services.*` and `systemd.user.services` -> `services`:
mako(notifier), udiskie (x2), hypridle, hyprpaper, hyprpolkitagent,
kdeconnect, xembed-sni-proxy, 1password, ssh-agent (security/ssh), laya,
llama-cpp, shikane, waybar, niri units, hyprland units.
`home.activation` DAG -> ordered oneshots or folded into the unit's ExecStart.
`home.sessionVariables` -> `environment`.

## Wave 3.75 — ai/clients -> opencode cluster — DONE

- All hdwlinux.ai.* option contributors mirrored into perUser (same module
  function in both scopes; text-duplicate or shared-let). Consumers that
  remain home-manager-side (claude-code, herdr, augment) read the hm-scope
  copy; opencode reads the perUser copy. One source expression, two scopes.
- programs/opencode hm-module replaced hand-rolled in perUser: opencode.json
  (incl. mcp transform + plugin list via new hdwlinux.programs.opencode.plugins
  contribution option), tui.json, themes/hdwlinux.json, prompts/*, skills/*.
  Submodules (grove-gateway, opencode-mem, ponytail, oh-my-opencode-slim) moved
  fully (their hm consumer is gone). Parity verified byte-equal against live
  HM output (opencode.json, tui, themes, mem, omos, 22/22 prompts, 19/19
  declarative skills; the 9 other live skills are runtime-installed regular
  files, untouched).
- laya: sidecar unit ported to schema services (device via graphics:nvidia
  tag instead of osConfig sniff); mcpServer + rule mirrored.
- secrets: untyped perUser option mirror (entries/outputDir) + users/craig
  entry mirror for github-mcp's build-time path interpolation. Retrieval
  machinery untouched (secrets wave).
- theming: colors/name/dark/wallpaper option mirror + catppuccin perUser value
  set. GTK/QT/cursor application stays home-manager-side (theming wave).
- llama-cpp: host/port option mirror only; server stays home-manager-side.
- musescore: plugin file + mcpServer mirrored; package stays.

## Wave 6 — hand-rolled replacements (hard)

- [ ] zsh/bash/starship/fzf/zoxide/direnv — ZDOTDIR/linkfarm rc generation
- [ ] programs.opencode hm-module replacement (settings JSON already mostly
      hand-built; skills/themes/mcp parts remain)
- [ ] dconf load unit; catppuccin color file generation
- [ ] xdg module (userDirs/mimeApps via files + tmpfiles-ish rules)
- [ ] nix-flatpak -> per-user flatpak-sync service
- [ ] noctalia/vicinae -> use their upstream nixosModules or wrap configs
- [ ] firefox (decision: NixOS programs.firefox.policies + user.js via files)
- [ ] secrets: per-user templates -> oneshot reading opnix output; HM DAG
      `retrieveOpnixSecrets` ordering replaced by unit deps

## Wave 7 — delete

- flake: home-manager input, substrateModules.home-manager,
  settings.homeManagerModules, programs.home-manager module, stateVersion
- substrate core untouched; `homeManager` blocks become hard errors once the
  class is unsupported

## Workflow quirks

- jj-managed git tree + nix dirty-copy: after creating a NEW module file, the
  first `nix eval` may read a stale store copy; a second eval sees it. Re-run
  before concluding a module is dead.

## Known pre-existing breakage (not caused by this migration)

- `nixosConfigurations.minimal` fails to evaluate: `hdwlinux.flake` has no
  value on hosts with no users (readers in modules/flake, modules/nix).
  Needs a default or `lib.mkIf` guards.
