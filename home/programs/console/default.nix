{ config, lib, repoDirectory, ... }: {
	imports = [
		./aws
		./azure
		./bash
		./bat
		./buf
		./direnv
		./fonts
		./fzf
		./gh
		./git
		./go
		./graphviz
		./jq
		./kube
		./lsd
		./micro
		./mongosh
		./ripgrep
		./ssh
		./starship
		./xclip
		./zoxide
	];
}
