{ config, lib, repoDirectory, ... }: {
	imports = [
		./aws
		./azure
		./bash
		./bat
		./btop
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
		./procps
		./ripgrep
		./ssh
		./starship
		./xclip
		./zoxide
	];
}
