{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.git;
in
{
  options.hdwlinux.features.git = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
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
          st = "status";
          sync = "!f() { export current_branch=`git branch-name` && git co $(git main-branch) && git pull upstream $(git main-branch) && git push origin $(git main-branch) && git co $current_branch && unset $current_branch; };f";
      };
      attributes = [
          "*.sh eol=lf"
      ];
      extraConfig = {
          commit.gpgsign = true;
          gpg.format = "ssh";
          gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
          pull.rebase = true;
          push.default = "current";
          rerere.enabled = true;
          submodule.recurse = true;
          url."git@github.com:".insteadOf = "https://github.com/";
          url."ssh://git@github.com/".insteadOf = "https://github.com/";
          user.signingkey = "~/.ssh/id_rsa.pub";
      };
      ignores = [
          ".idea"
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
  };
}
