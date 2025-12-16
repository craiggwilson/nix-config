{
  lib,
  ...
}:

final: prev:
let
  writeSwitchValue =
    value:
    if builtins.isAttrs value then
      writeSwitch value
    else if builtins.isString value then
      value
    else if builtins.isPath value then
      builtins.readFile value
    else
      throw "value must be of type attrs, string, or path";

  writeSwitchEntry = name: value: ''
    "${name}")
      shift
      ${writeSwitchValue value}
      ;;
  '';

  writeSwitch =
    subcommands:
    let
      subcommands' = lib.filterAttrs (n: _: n != "*") subcommands;
      subcommandNames = lib.mapAttrsToList (k: _: k) subcommands';
      subcommandNamesStr = lib.strings.concatStringsSep ", " subcommandNames;
      defaultCommand =
        if builtins.hasAttr "*" subcommands then
          writeSwitchValue subcommands."*"
        else
          ''
            if [[ $# -lt 1 ]]; then
              echo "expected one of ${subcommandNamesStr}"
            else
              echo "$1 is not a valid subcommand; expected one of ${subcommandNamesStr}"
            fi
            exit 1
          '';
    in
    if builtins.length subcommandNames == 0 then
      defaultCommand
    else
      ''
        case "''\${1-__default__}" in
          ${lib.strings.concatLines (lib.mapAttrsToList (k: v: writeSwitchEntry k v) subcommands')}
          * )
            ${defaultCommand}
          ;;
        esac
      '';
in
{
  hdwlinux = (prev.hdwlinux or { }) // {
    writeShellApplicationWithSubcommands =
      {
        name,
        runtimeInputs ? [ ],
        subcommands,
      }:
      prev.writeShellApplication {
        inherit name runtimeInputs;
        text = writeSwitch subcommands;
      };
  };
}
