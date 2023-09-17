{ config, lib, repoDirectory, ... }: {
	imports = [
		../../common/features/aws
		../../common/features/azure
		../../common/features/bash
		../../common/features/bat
		../../common/features/buf
		../../common/features/deckmaster
		../../common/features/direnv
		../../common/features/exa
		../../common/features/fonts
		../../common/features/fzf
		../../common/features/gh
		../../common/features/git
		../../common/features/go
		../../common/features/graphviz
		../../common/features/jq
		../../common/features/kube
		../../common/features/micro
		../../common/features/mongodb
		../../common/features/onedrive
		../../common/features/ripgrep
		../../common/features/ssh
		../../common/features/starship
		../../common/features/xclip
		../../common/features/zoxide

		./features/ssh
	] ++ lib.optional (builtins.pathExists ../../private/craig/default.nix) ../../private/craig;

  programs.home-manager.enable = true;
	systemd.user.startServices = true;

	home = { 
		stateVersion = "23.05";

		username = "craig";
		homeDirectory = "/home/craig";

		shellAliases = {
			start = "xdg-open";
			nix-config = "git -C ${repoDirectory}";
		};
	};
}
