{ config, lib, repoDirectory, ... }: {
	imports = [
		./calibre
		./compass
		./firefox
		./gimp
		./meld
		./musescore
		./slack
		./steam
		./virt-manager
		./vscode
		./wezterm
		./yuzu
		./zoom-us
	];
}
