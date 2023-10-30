{ lib, ... }: {
  mkWine = {
      name
      , pkgs
      , executable
      , args ? ""
      , winePrefix ? "$HOME/.wine-nix/${name}"
      , is64Bits ? false
      , wine ? if is64Bits then pkgs.wineWowPackages.stable else pkgs.wine
      , wineFlags ? ""
      , tricks ? [ ]
      , preCommands ? ""
      , postCommands ? ""
      , registryEntries ? null
    }:
    let
      wineBin = "${wine}/bin/wine${if is64Bits then "64" else ""}";
      wineServerBin = "${wine}/bin/wineserver";
      hasTricks = (builtins.length tricks) > 0;
      requiredPackages = [
        wine 
        pkgs.cabextract
      ] ++ lib.optionals hasTricks [ pkgs.winetricks ];
      tricksFmt =
        if hasTricks 
        then builtins.concatStringsSep " " tricks
        else "-V";
    in 
    pkgs.writeShellScriptBin name ''
      export APP_NAME="${name}"
      export WINEARCH=${if is64Bits then "win64" else "win32"}
      export PATH=$PATH:${lib.makeBinPath requiredPackages}
      export WINEPREFIX=${winePrefix}
      if [ ! -d "$WINEPREFIX" ]; then
        mkdir -p $WINEPREFIX
        ${pkgs.winetricks}/bin/winetricks -q -f ${tricksFmt}
        ${wineServerBin} -k
      fi
      ${preCommands}
      ${wineBin} ${wineFlags} "${executable}" ${args} "$@"
      ${postCommands}
      ${wineServerBin} -w
    '';
}
