# Helpers for the perUser class: config embedding and program wrapping.
#
# The core idea (shared with gurjaka's nati, minus theming): configuration
# lives in the store and reaches the program either by an embedded
# --config/--env flag at wrap time, or by a symlink into $HOME -- never by a
# mutable copy that home-manager used to manage.
#
# These functions are merged into `lib` for perUser modules (see eval.nix);
# `pkgs.lib // { wrap; embedDir; }` — plain nixpkgs lib plus the helpers.
#
# Theme note: colors are build-time inputs today (config.hdwlinux.theme.*).
# When nati-style live theming lands, switch call sites from embedded store
# files to $XDG_RUNTIME_DIR targets; wrap's `config.file` accepts any string.
{ lib, pkgs }:
{
  # A directory of immutable files (link farm). Values are coerced strings,
  # so text (via writeText), store paths, and paths all work alike.
  embedDir =
    name: files:
    pkgs.linkFarm "embedded-${name}" (
      lib.mapAttrsToList (k: v: {
        name = k;
        path = toString v;
      }) files
    );

  # One wrapper builder, everything declarative:
  #   wrap {
  #     pkg  = pkgs.zsh;              # package to wrap
  #     bin  = "zsh";                 # binary inside it
  #     env  = { ZDOTDIR = dir; };    # --set per key (export VAR=val)
  #     config = {                    # embed a config file by flag
  #       flag = "--config";          # default
  #       file = pkgs.writeText ...;  # any string-coercible path
  #     };
  #     args = [ "--login" ];         # extra --add-flags, in order
  #   }
  #
  # Applied order: env, then config flag, then args. Programs that need a
  # different order can be wrapped twice with different attrs.
  # Result carries passthru: { original; configPath?; } // extraPassthru.
  wrap =
    {
      pkg,
      bin,
      env ? { },
      config ? null,
      args ? [ ],
      name ? "${bin}-wrapped",
      extraPassthru ? { },
    }:
    let
      flags = lib.concatStringsSep " " (
        lib.optionals (config != null) [ "${config.flag or "--config"} ${toString config.file}" ]
        ++ lib.optionals (args != [ ]) [ (lib.escapeShellArgs args) ]
      );
    in
    pkgs.symlinkJoin {
      inherit name;
      paths = [ pkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/${bin} \
          ${
            lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "--set ${k} ${lib.escapeShellArg v}") env)
          } \
          ${lib.optionalString (flags != "") "--add-flags ${lib.escapeShellArg flags}"}
      '';
      passthru = {
        original = pkg;
      }
      // lib.optionalAttrs (config != null) {
        configPath = toString config.file;
      }
      // extraPassthru;
    };
}
