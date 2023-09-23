{ pkgs, config, lib, repoDirectory, ... }: {
	imports = [
		./common-home.nix

		../../home/programs/desktop
	];

	home.shellAliases = {
		nix-config-switch = "nix-config add -A . && sudo nixos-rebuild switch --flake ${repoDirectory}?submodules=1";
	};
}
