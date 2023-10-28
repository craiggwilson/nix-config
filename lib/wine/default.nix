{ pkgs, lib }: {
  mkWine = {
      is64bits ? false
      , wine ? if is64bits then pkgs.wineWowPackages.stable else pkgs.wine
      , wineFlags ? ""
      , executable
      , chdir ? null
      , name
      , tricks ? [ ]
      , setupScript ? ""
      , firstrunScript ? ""
      , home ? ""
    }:
    let
      wineBin = "${wine}/bin/wine${if is64bits then "64" else ""}";
      let hasTricks = (builtins.length tricks) > 0;
      requiredPackages = [
        wine 
        pkgs.cabextract
      ] ++ lib.optionals hasTricks [ pkgs.winetricks ];
      WINE_NIX_PROFILES = "$HOME/WINE_NIX_PROFILES";
      PATH = lib.makeBinPath requiredPackages;
      NAME = name;
      HOME = 
        if home == ""
        then "${WINE_NIX_PROFILES}/${name}"
        else home;
      WINEARCH =
        if is64bits
        then "win64"
        else "win32";
      setupHook = ''
        ${wine}/bin/wineboot
      '';
      tricksHook =
        if hasTricks then
          let
            tricksStr = builtins.concatStringsSep " " tricks;
            tricksCmd = ''
              pushd $(mktemp -d)
                ${pkgs.winetricks}/bin/winetricks ${tricksStr}
              popd
            '';
          in
            tricksCmd
        else "";
    in pkgs.writeShellScriptBin name ''
      export APP_NAME="${NAME}"
      export WINEARCH=${WINEARCH}
      export WINE_NIX="$HOME/.wine-nix"
      export WINE_NIX_PROFILES="${WINE_NIX_PROFILES}"
      export PATH=$PATH:${PATH}
      export HOME="${HOME}"
      mkdir -p "$HOME"
      export WINEPREFIX="$WINE_NIX/${name}"
      export EXECUTABLE="${executable}"
      mkdir -p "$WINE_NIX" "$WINE_NIX_PROFILES"
      ${setupScript}
      if [ ! -d "$WINEPREFIX" ] # if the prefix does not exist
      then
        ${setupHook}
        # ${wineBin} cmd /c dir > /dev/null 2> /dev/null # initialize prefix
        wineserver -w
        ${tricksHook}
        rm "$WINEPREFIX/drive_c/users/$USER" -rf
        ln -s "$HOME" "$WINEPREFIX/drive_c/users/$USER"
        ${firstrunScript}
      fi
      ${if chdir != null 
        then ''cd "${chdir}"'' 
        else ""}
      if [ ! "$REPL" == "" ]; # if $REPL is setup then start a shell in the context
      then
        bash
        exit 0
      fi

      ${wineBin} ${wineFlags} "$EXECUTABLE" "$@"
      wineserver -w
    '';
  }
}