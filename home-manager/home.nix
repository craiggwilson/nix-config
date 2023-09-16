{ lib, username, homeDirectory, repoDirectory, pkgsStable, ... }: {
	imports = [
		./features/aws
		./features/azure
		./features/bash
		./features/bat
		./features/buf
		./features/deckmaster
		./features/direnv
		./features/exa
		./features/fzf
		./features/gh
		./features/git
		./features/go
		./features/graphviz
		./features/jq
		./features/kube
		./features/micro
		./features/mongodb
		./features/onedrive
		./features/ripgrep
		./features/ssh
		./features/starship
		./features/xclip
		#./features/wezterm
		./features/zoxide
	] ++ lib.optional (builtins.pathExists ../private/home-manager/default.nix) ../private/home-manager;

	targets.genericLinux.enable = true;
  	programs.home-manager.enable = true;
	systemd.user.startServices = true;

	home = { 
		inherit username;
		inherit homeDirectory;
		stateVersion = "23.05";

		shellAliases = {
			start = "xdg-open";
			nix-repo = "git -C ${repoDirectory}";
			hm-switch = "nix-repo add -A . && home-manager switch --flake ${repoDirectory}?submodules=1";
		};
	};
}
