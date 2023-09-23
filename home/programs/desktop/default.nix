{ config, lib, repoDirectory, ... }: {
	imports = [
		./compass
		./firefox
		./musescore
		./wezterm
		./zoom-us
	];
}
