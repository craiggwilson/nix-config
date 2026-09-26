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

## Wave 2 — rename-only (custom `hdwlinux.*` option contributions)

Blocks that only contribute `hdwlinux.ai.*`, `hdwlinux.app`, `hdwlinux.theme`
option values or read them. They keep working under HM scope, but must gain
`perUser` duplicates (or move declarations) before their consumers migrate:

- modules/ai/clients/{agents,commands,rules,skills,mcp-servers,models}/* (~60 files)
- modules/apps/default.nix (generic + homeManager option decls)
- modules/theming/default.nix + theming/catppuccin (theme option decls —
  perUser needs its own `options.hdwlinux.theme.*` block; runtime theming
  itself is a later, nati-shaped feature)
- modules/users/craig/default.nix (hdwlinux.user, secrets decls)

## Wave 3 — packages-only (~58 files)

`home.packages` -> `packages`. Trivial. Includes most of
modules/programs/* (jq, ripgrep, vlc, ...).

## Wave 4 — config files (~25 files)

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
