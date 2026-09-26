# per-user

Substrate module class that replaces home-manager, developed here until
proven, then moved to `substrate/extensions/per-user`.

## Authoring

A module block has the same shape as `homeManager`. Inside it, `lib` is
nixpkgs lib *plus* the perUser helpers (`wrap`, `embedDir`) — no extra arg:

```nix
config.substrate.modules.programs.foo = {
  tags = [ "programming" ];

  perUser =
    { pkgs, lib, config, hostcfg, usercfg, inputs, hasTag, ... }:
    {
      packages = [ pkgs.foo ];
      files.".config/foo/config".text = ''...'';   # keys are $HOME-relative
      env.FOO_DATADIR = "''${config.homeDirectory}/.local/share/foo";
      services.foo-daemon = {
        description = "foo daemon";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        unitConfig.PartOf = [ "graphical-session.target" ];
        serviceConfig.ExecStart = "''${pkgs.foo}/bin/foo --daemon";
      };
    };
};
```

`perUser` blocks may also be plain attrsets when nothing dynamic is needed:
`perUser = { env.FOO = "bar"; };`.

Schema (`schema.nix`): `packages`, `files` (source-or-text → symlinked into
`$HOME`), `env` (session vars: linked environment.d + live
`systemctl --user set-environment`),
`services` (rendered to NixOS `systemd.user.services` with
`unitConfig.ConditionUser = <user>`, auto-`Wants/After` the activation unit).

## How it renders (`to-nixos.nix`)

Per (host, user): one activation unit `hdwlinux-<user>-<profile>.service`
(Type=oneshot, WantedBy=basic.target, ConditionUser) runs an idempotent
`ln -sfn` script over `files` + the environment.d link; existing non-symlink
files are preserved as `<file>.pre-per-user-backup`.

## Wrapping helpers (`lib.nix`, merged into `lib`)

- `wrap { pkg, bin, env ? {}, config ? { flag ? "--config", file },
    args ? [], name ? "<bin>-wrapped", extraPassthru ? {} }` — one declarative
  builder. Order applied: env sets, config flag, extra args (wrap twice if a
  program genuinely needs another order). Result carries
  `passthru.configPath` when `config` is set.
- `embedDir name files` — link farm of stringable entries; use with
  `env = { ZDOTDIR = embedDir "zsh" { ... }; }` for rcs-dir programs
  (zsh/bash).

Program selection rule: prefer `files` (XDK-cooperative programs); use
wrapping only when the program won't read a store/XDG path. Programs that
write back to their config at runtime are not wrap candidates — link instead
or accept store-defaults + local overrides.

Theme note: colors are build-time inputs today (`config.hdwlinux.theme.*`).
nati-style live theming = same call sites switching `file` to a
`$XDG_RUNTIME_DIR` target; keep palettes out of helper internals.

## Module map (wave tracker)

See MIGRATION.md at repo root for the per-file classification and status.
