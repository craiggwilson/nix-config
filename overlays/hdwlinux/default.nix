{
  lib,
  ...
}:

final: prev:
let
  concatMapAttrs = f: attrs: lib.concatStrings (lib.mapAttrsToList f attrs);
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
  hdwlinux = prev.hdwlinux // {
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

    writeJustApplication =
      {
        name,
        runtimeInputs ? [ ],
        modules,
      }:
      prev.stdenvNoCC.mkDerivation {
        inherit name;
        enableParallelBuilding = true;
        preferLocalBuild = true;
        allowSubstitutes = false;
        executable = true;
        #passAsFile = [ ];
        meta = {
          mainProgram = name;
        };
        buildCommand =
          let
            writeModules =
              modules:
              concatMapAttrs (name: value: ''
                ${writeModuleOrRecipes "${name}.just" value}
              '') modules;

            writeModuleOrRecipes =
              filename: value:
              if builtins.isAttrs value then writeModule filename value else writeRecipes filename value;

            writeModule =
              filename: modules:
              let
                modules' = lib.filterAttrs (n: _: n != "*") modules;
                text = if builtins.hasAttr "*" modules then modules."*" else "";
              in
              ''
                cat > "$out/share/${filename}" <<EOF
                ${concatMapAttrs (name: _: ''
                  mod ${name}
                '') modules'}
                ${text}
                EOF
                ${writeModules modules'}
              '';

            writeRecipes = filename: text: ''
              cat > "$out/share/${filename}" <<EOF
              ${text}
              EOF
            '';
          in
          ''
            mkdir -p "$out/bin"
            mkdir -p "$out/share"

            # Write the just files.
            ${writeModuleOrRecipes "justfile" modules}

            # Write the main program.
            cat > "$out/bin/${name}" <<EOF
            #!${prev.stdenvNoCC.shell}

            ${lib.optionalString (runtimeInputs != [ ]) ''
              export PATH="${lib.makeBinPath runtimeInputs}:$PATH"
            ''}

            just -f "$out/share/justfile" "\$@"
            EOF

            chmod +x "$out/bin/${name}"

            eval "$checkPhase"
          '';
      };
  };
}
