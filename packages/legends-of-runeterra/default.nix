{ lib, inputs, pkgs, stdenv, config, ...}:

stdenv.mkDerivation rec {
  name = "legends-of-runeterra";
  version = "0.1";

  src = pkgs.fetchurl {
    url = "https://bacon.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.live.americas.exe";
    sha256 = "sha256-OzJHZO/wSzp3/cRKi5FcJNF1jlfyEl5dhiWTxQ86Ca8=";
  };
  dontUnpack = true;

  winePrefix = "$HOME/.wine-nix/${name}";
  is64Bits = true;

  wine = inputs.nix-gaming.packages.${pkgs.system}.wine-lutris-ge-lol;

  preCommands = ''
    export DXVK_LOG_LEVEL=none
    export DXVK_STATE_CACHE_PATH=${winePrefix}
    export STAGING_SHARED_MEMORY=1
    export WINE_LARGE_ADDRESS_AWARE=1
    export __GL_SHADER_DISK_CACHE=1
    export __GL_SHADER_DISK_CACHE_PATH=${winePrefix}
  '';

  installer = lib.hdwlinux.mkWine {
    inherit pkgs winePrefix is64Bits wine preCommands;
    name = "${name}-installer";
    executable = src;
    tricks = [ 
      "wininet"
    ];
    postCommands = ''
      ${wine}/bin/wine64 reg add "HKCU\Software\Wine\Explorer" /v Desktop /t REG_SZ /d "Default"
      ${wine}/bin/wine64 reg add "HKCU\Software\Wine\Explorer\Desktops" /v Default /t REG_SZ /d "1920x1200"
    '';
  };

  launcher = lib.hdwlinux.mkWine {
    inherit name pkgs winePrefix is64Bits wine preCommands;
    executable = "${winePrefix}/drive_c/Riot Games/Riot Client/RiotClientServices.exe";
    args = "--launch-product=bacon --launch-patchline=live";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp $installer/bin/${name}-installer $out/bin/${name}-installer
    cp $launcher/bin/${name} $out/bin/${name}
    # chmod +x $out/bin/${name}
  '';

  meta = {
    mainProgram = name;
    description = "Legends of Runterra";
    platforms = [ "x86_64-linux" ];
  };
}
