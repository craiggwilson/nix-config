{
  config.substrate.modules.programs.git = {
    tags = [ "programming" ];

    # The single git config is assembled from ini fragments contributed by
    # this module plus delta/difftastic/mergiraf; fold them in declaration
    # order (recursiveUpdate, later fragments win per key).
    perUser =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.programs.git;
        user = config.hdwlinux.user;

        ini = lib.generators.toGitINI;

        mainFragment = {
          alias = {
            amend = "commit --amend --no-edit";
            branch-name = "branch --show-current";
            co = "checkout";
            conflicts = "diff --name-only --diff-filter=U";
            difft = "difftool -t difft";
            main-branch = "!git symbolic-ref refs/remotes/origin/HEAD | cut -d'/' -f4";
            recent = "for-each-ref --count=12 --sort=-committerdate refs/heads/ --format='%(refname:short)'";
          };
          blame.ignoreRevsFile = ".git-blame-ignore-revs";
          branch.sort = "-committerdate";
          commit = {
            gpgsign = true;
            verbose = true;
          };
          diff = {
            algorithm = "histogram";
            colorMoved = "default";
            colorMovedWS = "allow-indentation-change";
            context = 10;
          };
          fetch = {
            fsckobjects = true;
            prune = true;
            prunetags = true;
          };
          gpg = {
            format = "ssh";
            ssh.allowedSignersFile = "${config.homeDirectory}/.config/git/allowed_signers";
          };
          help.autocorrect = 10;
          init.defaultBranch = "main";
          merge = {
            conflictstyle = "zdiff3";
            keepBackup = false;
          };
          mergetool.hideResolved = true;
          pull.rebase = true;
          push = {
            autoSetupRemote = true;
            followtags = true;
          };
          rebase = {
            autosquash = true;
            autostash = true;
            updateRefs = true;
          };
          receive.fsckobjects = true;
          rerere.enabled = true;
          submodule.recurse = true;
          tag.sort = "taggerdate";
          transfer.fsckobjects = true;
          url = {
            "git@github.com:".insteadOf = "https://github.com/";
            "ssh://git@github.com/".insteadOf = "https://github.com/";
          };
          user = {
            email = user.email;
            name = user.fullName;
            signingkey = "~/.ssh/id_rsa.pub";
          };
          # git-lfs filter (home-manager's programs.git.lfs.enable)
          filter.lfs = {
            clean = "${pkgs.git-lfs}/bin/git-lfs clean -- %f";
            process = "${pkgs.git-lfs}/bin/git-lfs filter-process";
            required = true;
            smudge = "${pkgs.git-lfs}/bin/git-lfs smudge -- %f";
          };
        };
      in
      {
        options.hdwlinux.programs.git = {
          package = lib.mkOption {
            type = lib.types.nullOr lib.types.package;
            default = pkgs.git;
            description = "Git package to install, or null to manage separately.";
          };
          configFragments = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
            apply = lib.foldl' (a: b: lib.recursiveUpdate a b) { };
            description = "Git config ini fragments, merged in order (recursiveUpdate).";
          };
          ignores = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Lines for ~/.config/git/ignore.";
          };
          attributes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Lines for ~/.config/git/attributes.";
          };
        };

        config = {
          hdwlinux.programs.git.configFragments = [ mainFragment ];

          packages =
            (lib.optionals (cfg.package != null) [ cfg.package ])
            ++ [
              pkgs.git-lfs
              (pkgs.writeShellScriptBin "git-find" ''
                result=`${pkgs.git}/bin/git log -G"$1" --oneline | \
                    ${pkgs.fzf}/bin/fzf --ansi \
                      --exit-0 \
                      --delimiter " " \
                      --preview "${pkgs.git}/bin/git show {1} | ${pkgs.ripgrep}/bin/rg --ignore-case --color=always --line-number --context 1 $1" \
                        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' | \
                    cut -d' ' -f1`

                if [ ! -z $result ]; then
                  ${pkgs.git}/bin/git show $result
                fi
              '')
            ];

          files.".config/git/config".text = (ini cfg.configFragments) + "\n";

          files.".config/git/ignore".text = lib.concatStringsSep "\n" cfg.ignores + "\n";
          files.".config/git/attributes".text = lib.concatStringsSep "\n" cfg.attributes + "\n";

          files.".config/git/allowed_signers".text = ''
            ${user.email} ${user.publicKey}
          '';

          hdwlinux.programs.git = {
            ignores = [
              ".cheat"
              ".envrc"
              ".direnv"
              ".idea"
              ".jj"
              ".sisyphus"
              ".venv"
              ".vscode"
            ];
            attributes = [ "*.sh eol=lf" ];
          };
        };
      };

    # Still consumed by the home-manager side of security/ssh; moves with the
    # ssh cluster wave.
    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.security.ssh.knownHosts = [
          (pkgs.writeText "github_known_hosts" ''
            github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
            github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
            github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
          '')
        ];
      };
  };
}
