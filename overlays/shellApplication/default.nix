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
    cases:
    let
      validCases = lib.strings.concatStringsSep ", " (lib.mapAttrsToList (k: _: k) cases);
    in
    ''
      if [[ $# -lt 1 ]]; then
        echo "expected one of ${validCases}"
        exit 1
      fi
      case "$1" in
        ${lib.strings.concatLines (lib.mapAttrsToList (k: v: writeSwitchEntry k v) cases)}
        * )
          echo "$1 is not a valid subcommand; expected on of ${validCases}"
          exit 1
        ;;
      esac
    '';
in
{
  hdwlinux = prev.hdwlinux // {
    writeDelegateShellApplication =
      name:
      prev.writeShellApplication {
        inherit name;
        text = ''
          sub="$1"; shift
          # shellcheck source=/dev/null
          . ${name}-"$sub" "$@"
        '';
      };

    writeSwitchedShellApplication =
      {
        name,
        runtimeInputs ? [ ],
        cases,
      }:
      prev.writeShellApplication {
        inherit name runtimeInputs;
        text = writeSwitch cases;
      };
  };
}
