{ config, lib, repoDirectory, ... }: {
	imports = [
		./calibre
		./compass
		./firefox
		./gimp
		./goland
		./libreoffice
		./meld
		./musescore
		./obs-studio
		./slack
		./steam
		./virt-manager
		./vscode
		./wezterm
		./yuzu
		./zoom-us
	];
}
