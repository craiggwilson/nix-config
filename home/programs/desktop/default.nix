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
		./slack
		./steam
		./virt-manager
		./vscode
		./wezterm
		./yuzu
		./zoom-us
	];
}
