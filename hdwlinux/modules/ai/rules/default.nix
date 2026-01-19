let
  # Auto-discover all .md files in this directory
  dir = builtins.readDir ./.;
  mdFiles = builtins.filter (name: builtins.match ".*\\.md$" name != null) (builtins.attrNames dir);
  nameFromFile = file: builtins.replaceStrings [ ".md" ] [ "" ] file;
  rules = builtins.listToAttrs (
    map (file: {
      name = nameFromFile file;
      value = builtins.readFile (./. + "/${file}");
    }) mdFiles
  );
in
{
  config.substrate.modules.ai.rules = {
    generic =
      { lib, ... }:
      {
        options.hdwlinux.ai.rules = lib.mkOption {
          description = "Rule definitions.";
          type = lib.types.attrsOf lib.types.lines;
          default = { };
        };

        config.hdwlinux.ai.rules = rules;
      };
  };
}
