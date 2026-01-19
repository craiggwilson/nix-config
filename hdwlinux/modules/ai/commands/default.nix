let
  # Auto-discover all .md files in this directory
  dir = builtins.readDir ./.;
  mdFiles = builtins.filter (name: builtins.match ".*\\.md$" name != null) (builtins.attrNames dir);
  nameFromFile = file: builtins.replaceStrings [ ".md" ] [ "" ] file;
  commands = builtins.listToAttrs (
    map (file: {
      name = nameFromFile file;
      value = builtins.readFile (./. + "/${file}");
    }) mdFiles
  );
in
{
  config.substrate.modules.ai.commands = {
    generic =
      { lib, ... }:
      {
        options.hdwlinux.ai.commands = lib.mkOption {
          description = "Command definitions.";
          type = lib.types.attrsOf lib.types.lines;
          default = { };
        };

        config.hdwlinux.ai.commands = commands;
      };
  };
}
