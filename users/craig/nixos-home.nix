{ pkgs, config, lib, repoDirectory, ... }: {
	imports = [
		./common-home.nix
		../../common/features/wezterm
	];

	home.shellAliases = {
		nix-config-switch = "nix-config add -A . && sudo nixos-rebuild switch --flake ${repoDirectory}?submodules=1";
	};

	home.packages = with pkgs; [
		firefox
		musescore
		zoom-us
	];
}
