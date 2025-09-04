{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.jujutsu;
in
{
  options.hdwlinux.programs.jujutsu = {
    enable = config.lib.hdwlinux.mkEnableOption "jujutsu" "programming";
  };

  config = lib.mkIf cfg.enable {
    programs.jujutsu = {
      enable = true;

      settings = {
        aliases = {
          mine = [
            "log"
            "-r"
            "mutable() & mine() | bookmarks()::"
          ];

          retrunk = [
            "rebase"
            "-d"
            "trunk()"
          ];

          retrunk-all = [
            "rebase"
            "-s"
            "all:roots(trunk()..mutable())"
            "-d"
            "trunk()"
          ];

          sync = [
            "util"
            "exec"
            "--"
            "bash"
            "-c"
            ''
              branch=$(jj log -r "trunk()" -T "bookmarks" --no-graph)
              jj git fetch --branch "$branch"
              jj git push --bookmark "$branch"
              jj git fetch --remote origin
            ''
          ];

          tug = [
            "bookmark"
            "move"
            "--from"
            "closest_bookmark(@)"
            "--to"
            "closest_pushable(@)"
          ];
        };

        fsmonitor = {
          backend = "watchman";
          watchman.register-snapshot-trigger = true;
        };

        git = {
          colocate = true;
          private-commits = "private()";
          push-new-bookmarks = true;
          sign-on-push = true;
        };

        revset-aliases = {
          "closest_bookmark(to)" = "heads(::to & bookmarks() & ~private() & ~trunk())";
          "closest_pushable(to)" =
            ''heads(::to & mutable() & ~description(exact:" ") & (~empty() | merges()))'';
          "immutable_heads()" = "builtin_immutable_heads() | remote_bookmarks()";
          "private()" = "description(glob:'private:*')";
        };

        signing = {
          behavior = "own";
          backend = "ssh";
          key = "~/.ssh/id_rsa";
        };

        snapshot = {
          auto-update-stale = true;
        };

        ui = {
          conflict-marker-style = "git";
          default-command = [
            "log"
            "-r"
            "present(@) | ancestors(immutable_heads().., 2) | present(trunk())"
          ];
        };

        user = {
          email = config.hdwlinux.user.email;
          name = config.hdwlinux.user.fullName;
        };
      };
    };

    xdg.configFile."micro/syntax/jjdescription.yaml".source = ./micro-syntax.yaml;
  };
}
