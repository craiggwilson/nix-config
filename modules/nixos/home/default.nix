{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.home; 
in {
  options.hdwlinux.home = with types; {
    configFile = mkOpt attrs { } (mdDoc "A set of files to be managed by home-manager's `xdg.configFile`.");
    file = mkOpt attrs { } (mdDoc "A set of files to be managed by home-manager's `home.file`.");
    packages = mkOpt (listOf package) [ ] (mdDoc "A set of packages to be managed by home-manager's `home.packages`.");
    programs = mkOpt attrs {
      home-manager.enable = true;
    } (mdDoc "Options to pass directly to home-manager's `programs`.");
    services = mkOpt attrs { } (mdDoc "Options to pass directly to home-manager's `services`.");
    sessionVariables = mkOpt attrs { } (mdDoc "Options to pass directly to home-manager's `home.sessionVariables`.");
    shellAliases = mkOpt attrs { } (mdDoc "Options to pass directly to home-manager's `home.shellAliases`.");

    extraOptions = mkOpt attrs { } (mdDoc "Options to pass directly to home-manager's `users.<name>`.");
  };

  config = {
    hdwlinux.home.extraOptions = {
      home.stateVersion = config.system.stateVersion;
      home.file = mkAliasDefinitions options.hdwlinux.home.file;
      home.packages = mkAliasDefinitions options.hdwlinux.home.packages;
      home.sessionVariables = mkAliasDefinitions options.hdwlinux.home.sessionVariables;
      home.shellAliases = mkAliasDefinitions options.hdwlinux.home.shellAliases;
      
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.hdwlinux.home.configFile;

      programs = mkAliasDefinitions options.hdwlinux.home.programs;
      services = mkAliasDefinitions options.hdwlinux.home.services;

      systemd.user.startServices = true;
    };

    lib.file.mkOutOfStoreSymlink = path: 
      let
        pathStr = toString path;
        name = inputs.home-manager.lib.hm.strings.storeFileName (baseNameOf pathStr);
      in
        pkgs.runCommandLocal name {} ''ln -s ${lib.escapeShellArg pathStr} $out'';

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      users.${config.hdwlinux.user.name} = mkAliasDefinitions options.hdwlinux.home.extraOptions;
    };
  };
}
