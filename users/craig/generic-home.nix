{ config, lib, repoDirectory, ... }: {
	imports = [
		./common-home.nix
	];

  targets.genericLinux.enable = true;

	home.shellAliases = {
		nix-config-switch = "nix-config add -A . && home-manager switch --flake ${repoDirectory}?submodules=1";
	};
}
