{
  lib,
  ...
}:

final: prev:
let
  writeParserDefinition = path: spec: let
    hasSubcommands = builtins.hasAttr "subcommands" spec;
    anySubCommandHasOptions = if hasSubcommands then builtins.any (s: builtins.length s.options > 0) spec.subcommands else false;
    hasOptions = bulitins.hasAttr "options" spec && builtins.length spec.options > 0;
    hasGlobalOptions = hasOptions && hasSubcommands && builtins.length path == 1;
    usageStr = "Usage: ${lib.strings.concatStringsSep " " path}" + 
      (if hasGlobalOptions then 
        " [global options...]"
      else if hasOptions then 
        " [options...]"
      else "") + 
      (if hasSubcommands then " [command]" else "") +
      (if anySubCommandHasOptions then " [options...]" else "") +
      " [arguments...]";

    optionsStr = if hasOptions then
        lib.strings.concatStringsSep "\n  " spec.options;
      else "";
    commandsStr = if hasSubcommands then ''
        msg -- ''' 'Commands:' '''
        ${lib.strings.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "  cmd ${k} -- \"${v.doc}\"") spec.subcommands)}
      '' else "";
  in ''
    ${lib.strings.concatStringsSep "_" path}_parser_definition() {
      setup   REST help:usage -- \
        "${usageStr}"
      msg -- ''' ${spec.doc} '''
      msg -- 'Options:'
      disp :usage -h --help
      ${optionsStr}
      ${commandsStr}
    }
  '';

  writeParserDefinitions = path: spec: let 
      rootDefn = writeParserDefinition path spec;
      subDefns = writeSubcommandParserDefinitions path spec;
    in ''
      ${lib.strings.concatStringsSep "\n\n" ([rootDefn] ++ subDefns)}
    '';

  writeSubcommandParserDefinitions = path: spec: 
    if builtins.hasAttr "subcommands" spec then lib.mapAttrsToList (k: v: writeParserDefinitions (path ++ [k]) v) spec.subcommands else [];


  writeSpec = path: spec: let 
    in ''
      
  '';

  writeScript = path: spec: ''
    set -eu

    ${writeParserDefinitions path spec}

    eval "$(getoptions parser_definition) exit 1"
    if [ $# -gt 0 ]; then
      cmd=$1
      shift
      case $cmd in
        cmd1)
          eval "$(getoptions parser_definition_cmd1)"
          echo "FLAG_A: $FLAG_A"
          ;;
        cmd2)
          eval "$(getoptions parser_definition_cmd2)"
          echo "FLAG_B: $FLAG_B"
          ;;
        cmd3)
          eval "$(getoptions parser_definition_cmd3)"
          echo "FLAG_C: $FLAG_C"
          ;;
        --) # no subcommand, arguments only
      esac
    fi
  '';
in
{
  hdwlinux2 = prev.hdwlinux2 // {
    writeShellApplication =
      {
        name,
        runtimeInputs ? [ ],
        spec,
      }:
      prev.writeShellApplication {
        inherit name;
        runtimeInputs = runtimeInputs ++ [ prev.getoptions ];
        text = writeScript [name] spec;
      };
  };
}

/*
writeShellApplication {
  name = "myscript";
  doc = "";
  options = [    
    "flag FLAG -f --flag -- "
  ];
  subcommands = {
    mysubcommand = {
      doc = "";
      options = [];
      text = ''

      '';
    };
  };
}

*/