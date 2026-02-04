let
  # Auto-discover all subdirectories in this directory
  dir = builtins.readDir ./.;
  subdirs = builtins.filter (name: dir.${name} == "directory") (builtins.attrNames dir);
  skills = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = ./. + "/${name}";
    }) subdirs
  );
in
{
  config.substrate.modules.ai.skills = {
    generic =
      { lib, ... }:
      {
        options.hdwlinux.ai.skills = lib.mkOption {
          description = "Skill definitions (directories containing multiple files).";
          type = lib.types.attrsOf lib.types.path;
          default = { };
        };

        config.hdwlinux.ai.skills = skills;
      };
  };
}

