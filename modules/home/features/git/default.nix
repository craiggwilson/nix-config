{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.hdwlinux.features.git;
in
{
  options.hdwlinux.features.git = {
    enable = lib.hdwlinux.mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      aliases = {
        amend = "commit --amend --no-edit";
        "branch-name" = "branch --show-current";
        co = "checkout";
        conflicts = "diff --name-only --diff-filter=U";
        difft = "difftool -t difft";
        "pr-create" = "!gh pr create --web --fill";
        "pr-view" = "!gh pr view --web";
        "main-branch" = "!git symbolic-ref refs/remotes/origin/HEAD | cut -d'/' -f4";
        recent = "for-each-ref --count=12 --sort=-committerdate refs/heads/ --format='%(refname:short)'";
        #st = "status";
        #sync = "!f() { export current_branch=`git branch-name` && git co $(git main-branch) && git pull upstream $(git main-branch) && git push origin $(git main-branch) && git co $current_branch && unset $current_branch; };f";
      };
      attributes = [ "*.sh eol=lf" ];
      extraConfig = {
        commit.gpgsign = true;
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
        mergetool.hideResolved = true;
        pull.rebase = true;
        push.default = "current";
        rerere.enabled = true;
        submodule.recurse = true;
        url."git@github.com:".insteadOf = "https://github.com/";
        url."ssh://git@github.com/".insteadOf = "https://github.com/";
        user.signingkey = "~/.ssh/id_rsa.pub";
      };
      ignores = [
        ".cheat"
        ".envrc"
        ".direnv"
        ".idea"
        ".venv"
        ".vscode"
      ];
      lfs = {
        enable = true;
      };
      userEmail = config.hdwlinux.user.email;
      userName = config.hdwlinux.user.fullName;
    };

    xdg.configFile."/git/allowed_signers".text = ''
      ${config.hdwlinux.user.email} ${config.hdwlinux.user.publicKey}
    '';

    home.packages =
      lib.mkIf
        (
          config.hdwlinux.features.bash.enable
          && config.hdwlinux.features.fzf.enable
          && config.hdwlinux.features.ripgrep.enable
        )
        [
          pkgs.git-town
          (pkgs.writeShellScriptBin "git-find" ''
            result=`git log -G"$1" --oneline | \
                fzf --ansi \
                  --exit-0 \
                  --delimiter " " \
                  --preview "git show {1} | rg --ignore-case --color=always --line-number --context 1 $1" \
                    --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' | \
                cut -d' ' -f1`

            if [ ! -z $result ]; then
              git show $result
            fi
          '')
        ];

    hdwlinux.features.ssh.knownHosts = [
      (pkgs.writeText "github_known_hosts" ''
        github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
        github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
        github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
      '')
    ];
  };
}
