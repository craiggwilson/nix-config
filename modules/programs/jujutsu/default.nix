{
  config.substrate.modules.programs.jujutsu = {
    tags = [ "programming" ];

    homeManager =
      { config, pkgs, ... }:
      {
        programs.jujutsu = {
          enable = true;

          settings = {
            aliases = {
              editf = [
                "edit"
                "--ignore-immutable"
              ];

              mine = [
                "log"
                "-r"
                "mutable() & mine() | bookmarks()::"
              ];

              rebasef = [
                "rebase"
                "--ignore-immutable"
              ];

              squashf = [
                "squash"
                "--ignore-immutable"
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
                "advance"
                "-t"
                "@-"
              ];
            };

            fsmonitor = {
              backend = "watchman";
              watchman.register-snapshot-trigger = true;
            };

            git = {
              colocate = true;
              private-commits = "private()";
              sign-on-push = true;
              write-change-id-header = true;
            };

            remotes = {
              origin = {
                auto-track-bookmarks = "*";
              };
              upstream = {
                auto-track-bookmarks = "main";
              };
            };

            revset-aliases = {
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
                "--limit"
                "20"
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
  };
}
