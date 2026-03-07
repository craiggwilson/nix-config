{
  config.substrate.modules.programs.git = {
    tags = [ "programming" ];

    homeManager =
      { config, pkgs, ... }:
      {
        programs.git = {
          enable = true;
          attributes = [ "*.sh eol=lf" ];
          lfs.enable = true;
          ignores = [
            ".cheat"
            ".envrc"
            ".direnv"
            ".idea"
            ".venv"
            ".vscode"
          ];
          settings = {
            aliases = {
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
              ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
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
              email = config.hdwlinux.user.email;
              name = config.hdwlinux.user.fullName;
              signingkey = "~/.ssh/id_rsa.pub";
            };
          };
        };

        xdg.configFile."git/allowed_signers".text = ''
          ${config.hdwlinux.user.email} ${config.hdwlinux.user.publicKey}
        '';

        home.packages = [
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

