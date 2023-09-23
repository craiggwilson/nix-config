{ config, lib, repoDirectory, ... }: {
	imports = [
		../../home/programs/console
		../../home/services

		./programs/ssh
	] ++ lib.optional (builtins.pathExists ../../private/craig/default.nix) ../../private/craig;

  programs.home-manager.enable = true;
	systemd.user.startServices = true;

	home = { 
		stateVersion = "23.05";

		username = "craig";
		homeDirectory = "/home/craig";

		shellAliases = {
			start = "xdg-open";
			nix-config = "git -C ${repoDirectory}";
		};
	};
}
